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
import { bundleManager } from '@kit.AbilityKit';
import { CardRow, cardTitle, PageToolbar } from '../components/Common';
import { Nav } from '../common/Nav';
import { Radius, Space, STORE_HOST, STORE_URL } from '../common/Theme';
import { formatBytes } from '../common/Format';
import { AppContext } from '../common/AppContext';
import { cacheSize, clearCache } from '../utils/Cache';

@Styles
function card() {
  .backgroundColor($r('app.color.surface'))
  .borderRadius(Radius.L)
  .margin({ left: Space.GUTTER, right: Space.GUTTER })
}

export function selfVersion(): string {
  try {
    return bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName;
  } catch (err) {
    return '';
  }
}

@ComponentV2
export struct SettingsPage {
  @Local cacheBytes: number = 0;
  @Local clearing: boolean = false;
  private version: string = selfVersion();

  aboutToAppear(): void {
    this.measure();
  }

  measure(): void {
    this.cacheBytes = cacheSize(AppContext.filesDir);
  }

  build() {
    NavDestination() {
      Column() {
        PageToolbar({ title: $r('app.string.settings') })
        Scroll() {
          Column() {
            cardTitle($r('app.string.settings_storage'))
            Column() {
              CardRow({
                symbol: $r('sys.symbol.externaldrive'),
                title: $r('app.string.settings_cache'),
                detail: $r('app.string.settings_cache_desc'),
                value: this.cacheBytes > 0 ? formatBytes(this.cacheBytes) : AppContext.str($r('app.string.settings_cache_empty')),
                showDivider: this.cacheBytes > 0
              })
              if (this.cacheBytes > 0) {
                CardRow({
                  symbol: $r('sys.symbol.trash'),
                  symbolColor: $r('app.color.danger'),
                  title: $r('app.string.clear'),
                  showDivider: false,
                  onTap: () => this.confirmClear()
                })
              }
            }
            .card()

            cardTitle($r('app.string.settings_store'))
            Column() {
              CardRow({
                symbol: $r('sys.symbol.compass'),
                title: $r('app.string.settings_website'),
                value: STORE_HOST,
                chevron: true,
                showDivider: false,
                onTap: () => Nav.openWeb(STORE_HOST, STORE_URL)
              })
            }
            .card()

            cardTitle($r('app.string.settings_about'))
            Column() {
              CardRow({
                symbol: $r('sys.symbol.info_circle'),
                title: $r('app.string.about_title'),
                value: this.version,
                chevron: true,
                showDivider: false,
                onTap: () => Nav.openAbout()
              })
            }
            .card()
          }
          .width('100%')
          .padding({ bottom: Space.XXL })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
  }

  confirmClear(): void {
    if (this.clearing) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.confirm_clear_cache'),
      message: $r('app.string.clear_cache_warning'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: $r('app.string.clear'),
        fontColor: $r('app.color.danger'),
        action: () => {
          this.clearing = true;
          clearCache(AppContext.filesDir).then((ok: boolean) => {
            this.clearing = false;
            this.measure();
            AppContext.toast(ok ? $r('app.string.clear_cache_done') : $r('app.string.clear_cache_failed'));
          });
        }
      }
    });
  }
}
