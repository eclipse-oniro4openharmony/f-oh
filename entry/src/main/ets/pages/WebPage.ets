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
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MessageView, PageToolbar } from '../components/Common';
import { WebParams } from '../common/Nav';

/** A web page (source repositories, developer sites) inside the store. */
@ComponentV2
export struct WebPage {
  @Param @Require params: WebParams;
  @Local progress: number = 0;
  @Local failed: boolean = false;
  private controller: webview.WebviewController = new webview.WebviewController();

  reload(): void {
    this.failed = false;
    this.progress = 0;
    try {
      this.controller.refresh();
    } catch (err) {
      hilog.warn(0x0000, 'WebPage', 'refresh: %{public}s', (err as BusinessError).message);
    }
  }

  build() {
    NavDestination() {
      Column() {
        PageToolbar({
          title: this.params.title,
          trailingSymbol: $r('sys.symbol.arrow_clockwise'),
          onTrailing: () => this.reload()
        })
        Stack({ alignContent: Alignment.Top }) {
          Web({ src: this.params.url, controller: this.controller })
            .width('100%')
            .height('100%')
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .zoomAccess(true)
            .onProgressChange((event) => {
              if (event) {
                this.progress = event.newProgress;
              }
            })
            .onPageBegin(() => {
              this.failed = false;
            })
            .onErrorReceive((event) => {
              // Only a failed page counts, not a failed image or script on it.
              if (event && event.request.isMainFrame()) {
                this.failed = true;
              }
            })
            .visibility(this.failed ? Visibility.Hidden : Visibility.Visible)

          if (this.failed) {
            MessageView({
              symbol: $r('sys.symbol.wifi_slash'),
              title: $r('app.string.browser_load_failed'),
              body: this.params.url,
              actionLabel: $r('app.string.action_retry'),
              onAction: () => this.reload()
            })
          }

          if (this.progress < 100 && !this.failed) {
            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(2)
              .color($r('app.color.brand'))
              .backgroundColor(Color.Transparent)
              .style({ strokeWidth: 2, strokeRadius: 0 })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
  }
}
