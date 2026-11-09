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
import { AppInfo } from '../../model/AppInfo';
import { catalog, LoadState } from '../../data/Catalog';
import { AppState, installManager } from '../../data/InstallManager';
import { AppRow } from '../../components/AppRow';
import { ErrorView, MessageView, SkeletonRows, TabHeader } from '../../components/Common';
import { FontSize, Radius, Size, Space } from '../../common/Theme';
import { AppContext } from '../../common/AppContext';

const GROUP_DOWNLOADING: number = 0;
const GROUP_INSTALLED: number = 1;

function hasUpdate(app: AppInfo, s: AppState): boolean {
  return s.installed && s.installedVersionCode < app.latest.versionCode;
}

/**
 * Store apps on this device: pending updates (with Update all), downloads in
 * progress, and everything installed.
 */
@ComponentV2
export struct LibraryTab {
  @Event onBrowse: () => void = () => {
  };
  @Local pulling: boolean = false;

  updates(): AppInfo[] {
    return catalog.apps.filter((a: AppInfo) => hasUpdate(a, installManager.stateOf(a.packageName)));
  }

  downloading(): AppInfo[] {
    return catalog.apps.filter((a: AppInfo) => {
      const s: AppState = installManager.stateOf(a.packageName);
      return !s.installed && s.isBusy();
    });
  }

  installed(): AppInfo[] {
    return catalog.apps.filter((a: AppInfo) => {
      const s: AppState = installManager.stateOf(a.packageName);
      return s.installed && !hasUpdate(a, s);
    }).sort((a: AppInfo, b: AppInfo) => a.name.localeCompare(b.name));
  }

  build() {
    Column() {
      TabHeader({ title: $r('app.string.tab_library') })
      Refresh({ refreshing: $$this.pulling }) {
        if (catalog.state === LoadState.READY) {
          this.Content()
        } else if (catalog.state === LoadState.ERROR) {
          Scroll() {
            ErrorView({ onRetry: () => catalog.load(true) })
          }
          .height('100%')
        } else {
          Scroll() {
            SkeletonRows({ count: 5 })
          }
          .height('100%')
        }
      }
      .onRefreshing(() => {
        catalog.load(true).then((ok: boolean) => {
          this.pulling = false;
          if (!ok) {
            AppContext.toast($r('app.string.network_error'));
          }
        });
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
  }

  // The builders below read the lists themselves: @Builder arguments are
  // evaluated once, so passing them in would freeze the screen.
  @Builder
  Content() {
    if (this.updates().length + this.downloading().length + this.installed().length === 0) {
      Scroll() {
        MessageView({
          symbol: $r('sys.symbol.archivebox'),
          title: $r('app.string.library_empty_title'),
          body: $r('app.string.library_empty_body'),
          actionLabel: $r('app.string.library_browse'),
          onAction: () => this.onBrowse()
        })
      }
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    } else {
      List() {
        if (this.updates().length > 0) {
          ListItemGroup({ header: this.UpdatesHeader() }) {
            ForEach(this.updates(), (app: AppInfo) => {
              ListItem() {
                AppRow({ app: app, showVersionChange: true })
              }
            }, (app: AppInfo) => 'u-' + app.packageName)
          }
          .divider(this.rowDivider())
        } else {
          ListItem() {
            Column() {
              this.UpToDate()
            }
            .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.S })
          }
        }

        if (this.downloading().length > 0) {
          ListItemGroup({ header: this.GroupHeader($r('app.string.state_downloading'), GROUP_DOWNLOADING) }) {
            ForEach(this.downloading(), (app: AppInfo) => {
              ListItem() {
                AppRow({ app: app })
              }
            }, (app: AppInfo) => 'd-' + app.packageName)
          }
          .divider(this.rowDivider())
        }

        if (this.installed().length > 0) {
          ListItemGroup({ header: this.GroupHeader($r('app.string.library_installed'), GROUP_INSTALLED) }) {
            ForEach(this.installed(), (app: AppInfo) => {
              ListItem() {
                AppRow({ app: app })
              }
            }, (app: AppInfo) => 'i-' + app.packageName)
          }
          .divider(this.rowDivider())
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .contentEndOffset(Space.XL)
    }
  }

  rowDivider(): ListDividerOptions {
    return {
      strokeWidth: 0.5,
      color: $r('app.color.divider'),
      startMargin: Space.GUTTER + Size.ICON_M + Space.M,
      endMargin: Space.GUTTER
    };
  }

  groupCount(group: number): number {
    return group === GROUP_DOWNLOADING ? this.downloading().length : this.installed().length;
  }

  @Builder
  GroupHeader(title: Resource, group: number) {
    Row({ space: Space.S }) {
      Text(title)
        .fontSize(FontSize.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(this.groupCount(group).toString())
        .fontSize(FontSize.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.on_brand_soft'))
        .backgroundColor($r('app.color.brand_soft'))
        .borderRadius(Radius.PILL)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
    }
    .width('100%')
    .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.L, bottom: Space.XS })
    .backgroundColor($r('app.color.bg'))
  }

  @Builder
  UpdatesHeader() {
    Row({ space: Space.S }) {
      Text($r('app.string.library_updates'))
        .fontSize(FontSize.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text(this.updates().length.toString())
        .fontSize(FontSize.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.on_brand'))
        .backgroundColor($r('app.color.brand'))
        .borderRadius(Radius.PILL)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      Blank()
      Button($r('app.string.library_update_all'), { type: ButtonType.Capsule, stateEffect: true })
        .height(32)
        .padding({ left: Space.L, right: Space.L })
        .fontSize(FontSize.BODY_S)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.on_brand'))
        .backgroundColor($r('app.color.brand'))
        .onClick(() => installManager.updateAll(this.updates()))
    }
    .width('100%')
    .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.L, bottom: Space.XS })
    .backgroundColor($r('app.color.bg'))
  }

  @Builder
  UpToDate() {
    Row({ space: Space.M }) {
      SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
        .fontSize(24)
        .fontColor([$r('app.color.success')])
      Text($r('app.string.library_up_to_date'))
        .fontSize(FontSize.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(Space.L)
    .borderRadius(Radius.L)
    .backgroundColor($r('app.color.success_soft'))
  }
}
