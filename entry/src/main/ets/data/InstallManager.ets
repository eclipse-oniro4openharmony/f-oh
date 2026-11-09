/*
 * Copyright (C) 2023 westinyang https://gitee.com/ohos-dev
 * Copyright (C) 2026 Eclipse Oniro for OpenHarmony
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import fs from '@ohos.file.fs';
import { bundleManager, common, installer, Want } from '@kit.AbilityKit';
import { BusinessError, request } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppInfo, VersionInfo } from '../model/AppInfo';
import { AppContext } from '../common/AppContext';
import {
  InstallPlan,
  packagePath,
  packageWorkDir,
  planInstall,
  PlanStatus,
  removeDir,
  verifyPackage
} from '../utils/AppPackage';

const TAG: string = 'InstallManager';
// bundleInstaller InstallParam.installFlag: replace an installed version.
const REPLACE_EXISTING: number = 1;

export enum Phase {
  UNKNOWN = 0, // not checked against the device yet
  NOT_INSTALLED = 1,
  INSTALLED = 2, // the latest version, or newer
  UPDATABLE = 3,
  // Busy phases from here on.
  QUEUED = 4,
  DOWNLOADING = 5,
  VERIFYING = 6,
  INSTALLING = 7,
  UNINSTALLING = 8
}

/** What the device knows about one store app; every screen observes the same instance. */
@ObservedV2
export class AppState {
  packageName: string = '';
  @Trace phase: Phase = Phase.UNKNOWN;
  // Download progress 0..1, or -1 while the size is unknown.
  @Trace progress: number = -1;
  @Trace installed: boolean = false;
  @Trace installedVersionName: string = '';
  @Trace installedVersionCode: number = 0;

  constructor(packageName: string) {
    this.packageName = packageName;
  }

  isBusy(): boolean {
    return this.phase >= Phase.QUEUED;
  }

  /** Can the running download (or queue slot) still be cancelled? */
  isCancellable(): boolean {
    return this.phase === Phase.QUEUED || this.phase === Phase.DOWNLOADING;
  }
}

function errorMessage(err: Object): string {
  const e: BusinessError = err as BusinessError;
  return e.message ?? String(err);
}

function discard(path: string): void {
  try {
    if (fs.accessSync(path)) {
      fs.unlinkSync(path);
    }
  } catch (err) {
    hilog.warn(0x0000, TAG, 'discarding %{public}s failed: %{public}s', path, errorMessage(err));
  }
}

function planErrorMessage(status: PlanStatus): Resource {
  if (status === PlanStatus.DEVICE_UNSUPPORTED) {
    return $r('app.string.install_device_unsupported');
  }
  if (status === PlanStatus.NO_MODULES) {
    return $r('app.string.install_no_modules');
  }
  return $r('app.string.install_package_broken');
}

// Error.name of failures already explained to the user by a toast.
const REPORTED: string = 'Reported';

function reported(message: string): Error {
  const e: Error = new Error(message);
  e.name = REPORTED;
  return e;
}

/**
 * Downloads, verifies, installs, updates, opens and uninstalls store apps.
 * Installs run one at a time from a queue, so "Update all" and several taps
 * on Get never race inside the bundle installer.
 */
export class InstallManager {
  private states: Map<string, AppState> = new Map<string, AppState>();
  private queue: AppInfo[] = [];
  private running: boolean = false;
  private tasks: Map<string, request.DownloadTask> = new Map<string, request.DownloadTask>();
  private cancelHooks: Map<string, () => void> = new Map<string, () => void>();
  // Cancelled before its download task existed (while a cached package was checked).
  private cancelRequested: Set<string> = new Set<string>();

  stateOf(packageName: string): AppState {
    let s: AppState | undefined = this.states.get(packageName);
    if (s === undefined) {
      s = new AppState(packageName);
      this.states.set(packageName, s);
    }
    return s;
  }

  /** The store's own package: it can update itself but not open or uninstall itself. */
  isSelf(packageName: string): boolean {
    return AppContext.ability?.abilityInfo.bundleName === packageName;
  }

  /** Re-read which store apps are installed, and at which version. Never rejects. */
  async sync(apps: AppInfo[]): Promise<void> {
    // One lookup per store app (GET_BUNDLE_INFO_PRIVILEGED). getAllBundleInfo
    // would need GET_INSTALLED_BUNDLE_LIST, a user-granted permission.
    const infos: Array<bundleManager.BundleInfo | undefined> =
      await Promise.all(apps.map((app: AppInfo) => this.bundleInfo(app.packageName)));
    apps.forEach((app: AppInfo, i: number) => {
      this.apply(app, infos[i]);
    });
  }

  private async bundleInfo(packageName: string): Promise<bundleManager.BundleInfo | undefined> {
    try {
      return await bundleManager.getBundleInfo(packageName, bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    } catch (err) {
      return undefined; // not installed
    }
  }

  private apply(app: AppInfo, b: bundleManager.BundleInfo | undefined): void {
    const s: AppState = this.stateOf(app.packageName);
    s.installed = b !== undefined;
    s.installedVersionName = b?.versionName ?? '';
    s.installedVersionCode = b?.versionCode ?? 0;
    if (!s.isBusy()) {
      s.phase = this.restingPhase(app, s);
    }
  }

  private restingPhase(app: AppInfo, s: AppState): Phase {
    if (!s.installed) {
      return Phase.NOT_INSTALLED;
    }
    // versionCode, not versionName: a newer local build is not an "update".
    return s.installedVersionCode < app.latest.versionCode ? Phase.UPDATABLE : Phase.INSTALLED;
  }

  private async refresh(app: AppInfo): Promise<void> {
    this.apply(app, await this.bundleInfo(app.packageName));
  }

  /** What tapping the app's main button does in its current phase. */
  primary(app: AppInfo): void {
    const s: AppState = this.stateOf(app.packageName);
    if (s.isCancellable()) {
      this.cancel(app);
    } else if (s.phase === Phase.INSTALLED) {
      this.open(app);
    } else if (!s.isBusy()) {
      this.enqueue(app);
    }
  }

  /** Queue an install or update. */
  enqueue(app: AppInfo): void {
    const s: AppState = this.stateOf(app.packageName);
    if (s.isBusy()) {
      return;
    }
    if (!app.latest.downloadUrl) {
      AppContext.toast($r('app.string.download_link_invalid'));
      return;
    }
    s.phase = Phase.QUEUED;
    s.progress = -1;
    this.queue.push(app);
    this.pump();
  }

  updateAll(apps: AppInfo[]): void {
    apps.forEach((app: AppInfo) => {
      if (this.stateOf(app.packageName).phase === Phase.UPDATABLE) {
        this.enqueue(app);
      }
    });
  }

  cancel(app: AppInfo): void {
    const s: AppState = this.stateOf(app.packageName);
    if (s.phase === Phase.QUEUED) {
      this.queue = this.queue.filter((a: AppInfo) => a.packageName !== app.packageName);
      s.phase = this.restingPhase(app, s);
      return;
    }
    if (s.phase !== Phase.DOWNLOADING) {
      return; // verifying and installing run to completion
    }
    const task: request.DownloadTask | undefined = this.tasks.get(app.packageName);
    if (task !== undefined) {
      task.delete().catch((err: BusinessError) => {
        hilog.warn(0x0000, TAG, 'download delete failed: %{public}s', err.message);
      });
    }
    const hook: (() => void) | undefined = this.cancelHooks.get(app.packageName);
    if (hook !== undefined) {
      hook();
    } else {
      this.cancelRequested.add(app.packageName);
    }
  }

  private async pump(): Promise<void> {
    if (this.running) {
      return;
    }
    this.running = true;
    while (this.queue.length > 0) {
      const app: AppInfo = this.queue.shift() as AppInfo;
      await this.installOne(app);
    }
    this.running = false;
  }

  private async installOne(app: AppInfo): Promise<void> {
    const s: AppState = this.stateOf(app.packageName);
    const wasInstalled: boolean = s.installed;
    const v: VersionInfo = app.latest;
    const path: string = packagePath(AppContext.filesDir, app.packageName, v.versionName, v.format);
    let workDir: string = '';
    try {
      s.phase = Phase.DOWNLOADING;
      s.progress = -1;
      // A cached package from an earlier attempt is reused only if it verifies.
      const cachedOk: boolean = fs.accessSync(path) && await verifyPackage(path, v.sha256);
      if (!cachedOk) {
        discard(path);
        const completed: boolean = await this.download(app, path, s);
        if (!completed) {
          discard(path);
          AppContext.toast($r('app.string.toast_download_cancelled'));
          return;
        }
        s.phase = Phase.VERIFYING;
        s.progress = -1;
        if (!await verifyPackage(path, v.sha256)) {
          discard(path);
          AppContext.toast($r('app.string.install_verify_failed'));
          return;
        }
      }

      s.phase = Phase.INSTALLING;
      const plan: InstallPlan =
        await planInstall(path, v.format, packageWorkDir(AppContext.filesDir, app.packageName, v.versionName));
      workDir = plan.workDir;
      if (plan.status !== PlanStatus.OK) {
        if (plan.status === PlanStatus.UNPACK_FAILED) {
          discard(path);
        }
        AppContext.toast(planErrorMessage(plan.status));
        return;
      }
      const bundleInstaller: installer.BundleInstaller = await installer.getBundleInstaller();
      const param: installer.InstallParam = { installFlag: REPLACE_EXISTING };
      await bundleInstaller.install(plan.modules, param);
      // Installed: the package has done its job.
      discard(path);
      AppContext.toast(AppContext.str(wasInstalled ? $r('app.string.toast_updated') : $r('app.string.toast_installed'),
        app.name));
    } catch (err) {
      if ((err as Error).name !== REPORTED) {
        hilog.error(0x0000, TAG, 'installing %{public}s failed: %{public}s', app.packageName, errorMessage(err));
        AppContext.toast(AppContext.str($r('app.string.toast_install_failed'), app.name) + ': ' + errorMessage(err));
      }
    } finally {
      removeDir(workDir);
      this.cancelRequested.delete(app.packageName);
      s.phase = Phase.UNKNOWN; // leave the busy phases so refresh() settles it
      s.progress = -1;
      await this.refresh(app);
    }
  }

  /** Resolves true when the download completed, false when it was cancelled. */
  private download(app: AppInfo, path: string, s: AppState): Promise<boolean> {
    const ctx: common.UIAbilityContext | undefined = AppContext.ability;
    if (ctx === undefined) {
      return Promise.reject(new Error('no ability context'));
    }
    if (this.cancelRequested.delete(app.packageName)) {
      return Promise.resolve(false);
    }
    return new Promise<boolean>((resolve: (done: boolean) => void, reject: (e: Error) => void) => {
      let settled: boolean = false;
      const finish = (done: boolean, error?: Error): void => {
        if (settled) {
          return;
        }
        settled = true;
        this.tasks.delete(app.packageName);
        this.cancelHooks.delete(app.packageName);
        if (error !== undefined) {
          reject(error);
        } else {
          resolve(done);
        }
      };
      this.cancelHooks.set(app.packageName, () => finish(false));
      try {
        request.downloadFile(ctx, { url: app.latest.downloadUrl, filePath: path }).then((task: request.DownloadTask) => {
          if (settled) {
            // Cancelled before the task existed.
            task.delete().catch(() => {
            });
            return;
          }
          this.tasks.set(app.packageName, task);
          task.on('progress', (received: number, total: number) => {
            s.progress = total > 0 ? Math.min(received / total, 1) : -1;
          });
          task.on('complete', () => finish(true));
          task.on('remove', () => finish(false));
          task.on('fail', (code: number) => {
            AppContext.toast($r('app.string.download_failed'));
            finish(false, reported('download failed: ' + code));
          });
        }).catch((err: BusinessError) => {
          AppContext.toast($r('app.string.download_failed'));
          finish(false, reported(err.message));
        });
      } catch (err) {
        AppContext.toast($r('app.string.download_failed'));
        finish(false, reported(errorMessage(err)));
      }
    });
  }

  async open(app: AppInfo): Promise<void> {
    const ctx: common.UIAbilityContext | undefined = AppContext.ability;
    if (ctx === undefined || this.isSelf(app.packageName)) {
      return;
    }
    try {
      const want: Want = await bundleManager.getLaunchWantForBundle(app.packageName);
      await ctx.startAbility(want);
      return;
    } catch (err) {
      hilog.warn(0x0000, TAG, 'launch want for %{public}s: %{public}s', app.packageName, errorMessage(err));
    }
    // Fallback: the main ability of the entry module.
    try {
      const info: bundleManager.BundleInfo = await bundleManager.getBundleInfo(app.packageName,
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY);
      const mod: bundleManager.HapModuleInfo | undefined =
        info.hapModulesInfo.find((m: bundleManager.HapModuleInfo) => !!m.mainElementName);
      if (mod === undefined) {
        throw new Error('no main ability');
      }
      await ctx.startAbility({ bundleName: app.packageName, moduleName: mod.name, abilityName: mod.mainElementName });
    } catch (err) {
      hilog.error(0x0000, TAG, 'opening %{public}s failed: %{public}s', app.packageName, errorMessage(err));
      AppContext.toast($r('app.string.open_failed_app_not_found'));
      await this.refresh(app);
    }
  }

  async uninstall(app: AppInfo): Promise<void> {
    const s: AppState = this.stateOf(app.packageName);
    if (s.isBusy() || !s.installed || this.isSelf(app.packageName)) {
      return;
    }
    s.phase = Phase.UNINSTALLING;
    try {
      const bundleInstaller: installer.BundleInstaller = await installer.getBundleInstaller();
      await bundleInstaller.uninstall(app.packageName);
      AppContext.toast(AppContext.str($r('app.string.toast_uninstalled'), app.name));
    } catch (err) {
      hilog.error(0x0000, TAG, 'uninstalling %{public}s failed: %{public}s', app.packageName, errorMessage(err));
      AppContext.toast(AppContext.str($r('app.string.toast_uninstall_failed'), app.name));
    } finally {
      s.phase = Phase.UNKNOWN;
      await this.refresh(app);
    }
  }
}

export const installManager: InstallManager = new InstallManager();
