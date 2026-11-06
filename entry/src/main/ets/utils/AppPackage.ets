// 应用安装包处理：.hap 为单个模块，.app 为模块压缩包（bundle）
import fs from '@ohos.file.fs';
import { BusinessError, deviceInfo, zlib } from '@kit.BasicServicesKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

/** Package formats served by the store: a single module, or a bundle of them. */
export const FORMAT_HAP: string = 'hap';
export const FORMAT_APP: string = 'app';

const TAG: string = 'AppPackage';

export enum PlanStatus {
  OK = 0,
  UNPACK_FAILED = 1, // the bundle could not be unpacked
  NO_MODULES = 2, // unpacked, but nothing installable inside
  DEVICE_UNSUPPORTED = 3, // modules inside, none of them built for this device
}

/** What to hand to the bundle installer, and where it was unpacked. */
export interface InstallPlan {
  status: PlanStatus;
  // Module files to install together; empty unless status is OK.
  modules: string[];
  // Scratch directory holding the unpacked modules; '' for a plain .hap.
  workDir: string;
}

// pack.info, the manifest an .app bundle carries next to its modules.
interface PackInfoPackage {
  name?: string;
  moduleType?: string;
  deviceType?: string[];
}

interface PackInfo {
  packages?: PackInfoPackage[];
}

/** File a download is cached under, e.g. <files>/com.example.app-1.0.0.app */
export function packagePath(filesDir: string, packageName: string, version: string, format: string): string {
  const extension: string = format === FORMAT_APP ? FORMAT_APP : FORMAT_HAP;
  return filesDir + '/' + packageName + '-' + version + '.' + extension;
}

// Packages can be hundreds of MB, so they are hashed a chunk at a time.
const HASH_CHUNK_BYTES: number = 1024 * 1024;

function toHex(bytes: Uint8Array): string {
  let hex: string = '';
  for (let i = 0; i < bytes.length; i++) {
    hex += (bytes[i] < 16 ? '0' : '') + bytes[i].toString(16);
  }
  return hex;
}

/**
 * SHA-256 of a file as lowercase hex, read in chunks rather than whole.
 * Never rejects: a file that cannot be read hashes to ''.
 */
export async function sha256OfFile(path: string): Promise<string> {
  let file: fs.File | null = null;
  try {
    const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
    file = await fs.open(path, fs.OpenMode.READ_ONLY);
    const buffer: ArrayBuffer = new ArrayBuffer(HASH_CHUNK_BYTES);
    let offset: number = 0;
    while (true) {
      const read: number = await fs.read(file.fd, buffer, { offset: offset, length: HASH_CHUNK_BYTES });
      if (read <= 0) {
        break;
      }
      const chunk: Uint8Array = read === HASH_CHUNK_BYTES ? new Uint8Array(buffer) :
        new Uint8Array(buffer.slice(0, read));
      await md.update({ data: chunk });
      offset += read;
    }
    const digest: cryptoFramework.DataBlob = await md.digest();
    return toHex(digest.data);
  } catch (err) {
    hilog.error(0x0000, TAG, 'hashing %{public}s failed: %{public}s', path, (err as BusinessError).message);
    return '';
  } finally {
    if (file !== null) {
      try {
        fs.closeSync(file);
      } catch (err) {
        hilog.warn(0x0000, TAG, 'close failed: %{public}s', (err as BusinessError).message);
      }
    }
  }
}

/**
 * Whether the file at `path` is the package the store published. The store
 * reports the SHA-256 of the exact bytes it serves, including packages hosted
 * on GitHub (whose release assets can be replaced after publication), so any
 * difference means a corrupted, stale or substituted file. An empty
 * `expected` (an older server that reports no hash) is not checked.
 * Never rejects: an unreadable file counts as a mismatch.
 */
export async function verifyPackage(path: string, expected: string): Promise<boolean> {
  if (!expected) {
    return true;
  }
  const actual: string = await sha256OfFile(path);
  if (actual === expected.toLowerCase()) {
    return true;
  }
  hilog.error(0x0000, TAG, 'sha256 mismatch for %{public}s: expected %{public}s, got %{public}s', path, expected,
    actual || '(unreadable)');
  return false;
}

/** Directory an .app bundle is unpacked into before its modules are installed. */
export function packageWorkDir(filesDir: string, packageName: string, version: string): string {
  return filesDir + '/' + packageName + '-' + version + '.modules';
}

/** Delete an unpack directory and the files in it; bundles unpack flat. */
export function removeDir(dir: string): void {
  if (!dir) {
    return;
  }
  try {
    if (!fs.accessSync(dir)) {
      return;
    }
    fs.listFileSync(dir).forEach((name: string) => {
      try {
        fs.unlinkSync(dir + '/' + name);
      } catch (err) {
        hilog.warn(0x0000, TAG, 'unlink failed: %{public}s', (err as BusinessError).message);
      }
    });
    fs.rmdirSync(dir);
  } catch (err) {
    hilog.warn(0x0000, TAG, 'rmdir failed: %{public}s', (err as BusinessError).message);
  }
}

function isModuleFile(name: string): boolean {
  return name.endsWith('.hap') || name.endsWith('.hsp');
}

function baseName(fileName: string): string {
  const dot: number = fileName.lastIndexOf('.');
  return dot < 0 ? fileName : fileName.substring(0, dot);
}

/**
 * Whether a module built for these device types runs on this device.
 * 'default' is the generic phone-shaped device type, which OpenHarmony reports
 * as either 'default' or 'phone' depending on the build, so the two match.
 */
function runsOnThisDevice(deviceTypes: string[]): boolean {
  const own: string = deviceInfo.deviceType;
  if (deviceTypes.indexOf(own) >= 0) {
    return true;
  }
  if (own === 'default' || own === 'phone') {
    return deviceTypes.indexOf('default') >= 0 || deviceTypes.indexOf('phone') >= 0;
  }
  return false;
}

/**
 * The pack.info entry describing a module file. A packing tool keeps the file
 * name it was handed, which is usually the package name but can carry a suffix
 * (mobile-default-signed.hap for package mobile-default), so the longest
 * package name that prefixes the file name wins.
 */
function packageFor(fileName: string, packages: PackInfoPackage[]): PackInfoPackage | null {
  const base: string = baseName(fileName);
  let best: PackInfoPackage | null = null;
  let bestLength: number = -1;
  packages.forEach((pkg: PackInfoPackage) => {
    const name: string = pkg.name ?? '';
    if (name.length > bestLength && base.startsWith(name)) {
      best = pkg;
      bestLength = name.length;
    }
  });
  return best;
}

function readPackInfo(dir: string): PackInfo | null {
  const path: string = dir + '/pack.info';
  try {
    if (!fs.accessSync(path)) {
      return null;
    }
    return JSON.parse(fs.readTextSync(path)) as PackInfo;
  } catch (err) {
    hilog.warn(0x0000, TAG, 'pack.info unreadable: %{public}s', (err as BusinessError).message);
    return null;
  }
}

function plan(status: PlanStatus, modules: string[], workDir: string): InstallPlan {
  const result: InstallPlan = { status: status, modules: modules, workDir: workDir };
  return result;
}

/**
 * Work out what bundleInstaller.install() should be given for a download.
 *
 * A .hap is a single module and installs as it is. An .app is a zip of every
 * module of one bundle — including modules built for other device types — so
 * it is unpacked and only the modules this device can run are picked, all in
 * one install call, because the modules of a bundle install together.
 *
 * Never rejects: failures come back as a PlanStatus for the caller to report.
 */
export async function planInstall(pkgPath: string, format: string, workDir: string): Promise<InstallPlan> {
  if (format !== FORMAT_APP) {
    return plan(PlanStatus.OK, [pkgPath], '');
  }

  removeDir(workDir); // modules left behind by an earlier attempt
  let fileNames: string[] = [];
  try {
    fs.mkdirSync(workDir, true);
    await zlib.decompressFile(pkgPath, workDir);
    fileNames = fs.listFileSync(workDir);
  } catch (err) {
    hilog.error(0x0000, TAG, 'unpacking %{public}s failed: %{public}s', pkgPath, (err as BusinessError).message);
    removeDir(workDir);
    return plan(PlanStatus.UNPACK_FAILED, [], '');
  }

  const modules: string[] = fileNames.filter((name: string) => isModuleFile(name));
  if (modules.length === 0) {
    hilog.error(0x0000, TAG, 'bundle %{public}s holds no module', pkgPath);
    removeDir(workDir);
    return plan(PlanStatus.NO_MODULES, [], '');
  }

  const info: PackInfo | null = readPackInfo(workDir);
  const packages: PackInfoPackage[] | undefined = info?.packages;
  if (packages === undefined) {
    // Nothing to select on: hand over every module and let the installer judge.
    hilog.warn(0x0000, TAG, 'bundle %{public}s has no usable pack.info', pkgPath);
    return plan(PlanStatus.OK, modules.map((name: string) => workDir + '/' + name), workDir);
  }

  const selected: string[] = [];
  let described: number = 0;
  modules.forEach((fileName: string) => {
    const pkg: PackInfoPackage | null = packageFor(fileName, packages);
    if (pkg === null) {
      return;
    }
    described++;
    if (runsOnThisDevice(pkg.deviceType ?? [])) {
      selected.push(fileName);
    }
  });
  if (selected.length === 0) {
    if (described === 0) {
      // pack.info describes none of these files; hand over everything instead.
      hilog.warn(0x0000, TAG, 'bundle %{public}s: pack.info matches no module file', pkgPath);
      return plan(PlanStatus.OK, modules.map((name: string) => workDir + '/' + name), workDir);
    }
    hilog.error(0x0000, TAG, 'bundle %{public}s has no module for device type %{public}s', pkgPath,
      deviceInfo.deviceType);
    removeDir(workDir);
    return plan(PlanStatus.DEVICE_UNSUPPORTED, [], '');
  }

  hilog.info(0x0000, TAG, 'installing %{public}d of %{public}d modules of %{public}s', selected.length, modules.length,
    pkgPath);
  return plan(PlanStatus.OK, selected.map((name: string) => workDir + '/' + name), workDir);
}
