/*
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
import { AppInfo } from '../model/AppInfo';
import { AppState, installManager, Phase } from '../data/InstallManager';
import { FontSize, Radius, Size, Space } from '../common/Theme';
import { formatBytes } from '../common/Format';
import { AppContext } from '../common/AppContext';

const WIDE_HEIGHT: number = 44;

/** Label of the idle (not busy) button for a phase. */
function idleLabel(phase: Phase, self: boolean): Resource {
  if (phase === Phase.UPDATABLE) {
    return $r('app.string.action_update');
  }
  if (phase === Phase.INSTALLED) {
    return self ? $r('app.string.badge_installed') : $r('app.string.action_open');
  }
  return $r('app.string.action_get');
}

function busyLabel(phase: Phase): Resource {
  if (phase === Phase.QUEUED) {
    return $r('app.string.state_waiting');
  }
  if (phase === Phase.DOWNLOADING) {
    return $r('app.string.state_downloading');
  }
  if (phase === Phase.VERIFYING) {
    return $r('app.string.state_verifying');
  }
  if (phase === Phase.UNINSTALLING) {
    return $r('app.string.state_uninstalling');
  }
  return $r('app.string.state_installing');
}

/**
 * The Get / Open / Update button of an app. It reads the shared AppState, so
 * a download started on one screen shows its progress on every other.
 * Compact (list rows): a pill that turns into a progress ring with a stop
 * square while downloading. Wide (detail page): full-width buttons and a
 * labelled progress bar.
 */
@ComponentV2
export struct ActionButton {
  @Param @Require app: AppInfo;
  @Param @Require appState: AppState;
  @Param wide: boolean = false;

  build() {
    if (this.wide) {
      this.Wide()
    } else {
      this.Compact()
    }
  }

  // ---- compact ----

  @Builder
  Compact() {
    Stack() {
      if (this.appState.isBusy()) {
        Stack() {
          if (this.appState.phase === Phase.DOWNLOADING && this.appState.progress >= 0) {
            Progress({ value: this.appState.progress * 100, total: 100, type: ProgressType.Ring })
              .width(30)
              .height(30)
              .color($r('app.color.brand'))
              .backgroundColor($r('app.color.surface_variant'))
              .style({ strokeWidth: 3 })
          } else {
            LoadingProgress()
              .width(32)
              .height(32)
              .color($r('app.color.brand'))
          }
          if (this.appState.isCancellable()) {
            // Stop square: tap to cancel.
            Column()
              .width(8)
              .height(8)
              .borderRadius(2)
              .backgroundColor($r('app.color.brand'))
          }
        }
        .width(Size.ACTION_W)
        .height(Size.ACTION_H + 8)
        .onClick(() => installManager.cancel(this.app))
      } else {
        Button(idleLabel(this.appState.phase, installManager.isSelf(this.app.packageName)),
          { type: ButtonType.Capsule, stateEffect: true })
          .width(Size.ACTION_W)
          .height(Size.ACTION_H)
          .padding(0)
          .fontSize(FontSize.BODY_S + 1)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.compactText())
          .backgroundColor(this.compactBackground())
          .stateEffect(!this.isSelfInstalled())
          .onClick(() => installManager.primary(this.app))
      }
    }
    .flexShrink(0)
  }

  compactBackground(): ResourceColor {
    if (this.appState.phase === Phase.UPDATABLE) {
      return $r('app.color.brand');
    }
    if (this.appState.phase === Phase.INSTALLED) {
      return $r('app.color.surface_variant');
    }
    return $r('app.color.brand_soft');
  }

  compactText(): ResourceColor {
    if (this.appState.phase === Phase.UPDATABLE) {
      return $r('app.color.on_brand');
    }
    if (this.appState.phase === Phase.INSTALLED) {
      return this.isSelfInstalled() ? $r('app.color.text_tertiary') : $r('app.color.brand');
    }
    return $r('app.color.on_brand_soft');
  }

  isSelfInstalled(): boolean {
    return this.appState.phase === Phase.INSTALLED && installManager.isSelf(this.app.packageName);
  }

  // ---- wide ----

  @Builder
  Wide() {
    Column() {
      if (this.appState.isBusy()) {
        this.WideProgress()
      } else {
        this.WideButtons()
      }
    }
    .width('100%')
  }

  @Builder
  WideProgress() {
    Row({ space: Space.M }) {
      Column({ space: Space.S }) {
        Row() {
          Text(busyLabel(this.appState.phase))
            .fontSize(FontSize.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          if (this.appState.phase === Phase.DOWNLOADING && this.appState.progress >= 0) {
            Text(this.progressDetail())
              .fontSize(FontSize.CAPTION)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .width('100%')

        if (this.appState.phase === Phase.DOWNLOADING && this.appState.progress >= 0) {
          Progress({ value: this.appState.progress * 100, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .color($r('app.color.brand'))
            .backgroundColor($r('app.color.surface_variant'))
            .style({ strokeWidth: 6, strokeRadius: 3, enableSmoothEffect: true })
        } else {
          Progress({ value: 100, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .color($r('app.color.brand'))
            .backgroundColor($r('app.color.surface_variant'))
            .style({ strokeWidth: 6, strokeRadius: 3, enableScanEffect: true })
        }
      }
      .layoutWeight(1)

      if (this.appState.isCancellable()) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(18)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(WIDE_HEIGHT)
        .height(WIDE_HEIGHT)
        .backgroundColor($r('app.color.surface_variant'))
        .onClick(() => installManager.cancel(this.app))
      }
    }
    .width('100%')
    .height(WIDE_HEIGHT)
  }

  progressDetail(): string {
    const total: number = this.app.latest.fileSize;
    const pct: string = Math.round(this.appState.progress * 100) + '%';
    if (total <= 0) {
      return pct;
    }
    return formatBytes(total * this.appState.progress) + ' / ' + formatBytes(total) + '  ·  ' + pct;
  }

  @Builder
  WideButtons() {
    Row({ space: Space.M }) {
      // Primary: Get, Update or Open.
      Button(idleLabel(this.appState.phase, installManager.isSelf(this.app.packageName)),
        { type: ButtonType.Capsule, stateEffect: true })
        .layoutWeight(1)
        .height(WIDE_HEIGHT)
        .fontSize(FontSize.TITLE_S)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isSelfInstalled() ? $r('app.color.text_tertiary') : $r('app.color.on_brand'))
        .backgroundColor(this.isSelfInstalled() ? $r('app.color.surface_variant') : $r('app.color.brand'))
        .stateEffect(!this.isSelfInstalled())
        .onClick(() => installManager.primary(this.app))

      // Secondary: Open next to Update; Uninstall next to Open.
      if (this.appState.phase === Phase.UPDATABLE && !installManager.isSelf(this.app.packageName)) {
        Button($r('app.string.action_open'), { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(WIDE_HEIGHT)
          .fontSize(FontSize.TITLE_S)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.brand'))
          .backgroundColor($r('app.color.brand_soft'))
          .onClick(() => installManager.open(this.app))
      } else if (this.appState.phase === Phase.INSTALLED && !installManager.isSelf(this.app.packageName)) {
        Button($r('app.string.action_uninstall'), { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(WIDE_HEIGHT)
          .fontSize(FontSize.TITLE_S)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.danger'))
          .backgroundColor($r('app.color.danger_soft'))
          .onClick(() => this.confirmUninstall())
      }
    }
    .width('100%')
  }

  confirmUninstall(): void {
    this.getUIContext().showAlertDialog({
      title: AppContext.str($r('app.string.uninstall_confirm_title'), this.app.name),
      message: $r('app.string.uninstall_confirm_body'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: $r('app.string.action_uninstall'),
        fontColor: $r('app.color.danger'),
        action: () => {
          installManager.uninstall(this.app);
        }
      }
    });
  }
}

/** A small "Installed" / "Update" tag for compact cards. */
@ComponentV2
export struct StatusTag {
  @Param @Require appState: AppState;

  build() {
    if (this.appState.phase === Phase.INSTALLED || this.appState.phase === Phase.UPDATABLE) {
      Text(this.appState.phase === Phase.UPDATABLE ? $r('app.string.badge_update') : $r('app.string.badge_installed'))
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.appState.phase === Phase.UPDATABLE ? $r('app.color.on_brand') : $r('app.color.success'))
        .backgroundColor(this.appState.phase === Phase.UPDATABLE ? $r('app.color.brand') :
        $r('app.color.success_soft'))
        .borderRadius(Radius.PILL)
        .padding({ left: 6, right: 6, top: 1, bottom: 1 })
    } else if (this.appState.isBusy()) {
      Text(busyLabel(this.appState.phase))
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.on_brand_soft'))
        .backgroundColor($r('app.color.brand_soft'))
        .borderRadius(Radius.PILL)
        .padding({ left: 6, right: 6, top: 1, bottom: 1 })
    }
  }
}
