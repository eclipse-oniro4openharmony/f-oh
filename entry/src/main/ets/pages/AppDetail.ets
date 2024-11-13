/*
 * Copyright (C) 2023 westinyang https://gitee.com/ohos-dev
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

import router from '@ohos.router'
import { InfoRow } from '../components/InfoRow';
import { AppInfo } from '../model/AppInfo';
import WindowStageUtil from '../utils/WindowStageUtil';

export interface RouterParams {
  appInfo?: AppInfo;
  localVersionName?: string;
}

@Entry
@Component
struct AppDetail {
  @State appInfo: AppInfo = new AppInfo()
  @State localVersionName: string = '--';
  @State localParams: RouterParams | null = null;

  onPageShow() {
    const params = router.getParams() as RouterParams
    this.localParams = params
    this.appInfo = new AppInfo(params.appInfo)
    this.localVersionName = params.localVersionName as string
    // todo: uncomment later
    console.info('AboutComponent onPageShow');
    // WindowStageUtil.setLayoutFullScreen(globalThis.windowStage, '#ffffff', WindowStageUtil.COLOR_BLACK, '#ffffff', WindowStageUtil.COLOR_BLACK);
  }

  @Builder
  NavigationTitle() {
    Column() {
      Text($r('app.string.app_details'))
        .fontColor('#182431')
        .fontSize(26)
        .fontWeight(500)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 页面标题
        Navigation()
          .title(this.NavigationTitle())
          .hideToolBar(true)
          .height(56)
          .width('100%')
          .titleMode(NavigationTitleMode.Mini)
          .hideBackButton(false)

        Scroll() {
          Column() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              // 左 应用图标
              Image(this.appInfo.getIcon() || $r('app.media.icon_default'))
                .width(100)
                .height(100)
                .border({ width: 0.7, radius: 23, color: '#ebebeb' })
                .flexShrink(0)
              //        .backgroundColor('#00f')

              // 右 应用信息
              Column() {
                Text(this.appInfo.name)
                  .fontSize(19)
                  .margin({ top: 2, bottom: 5 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.appInfo.desc).fontSize(14).maxLines(4).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .height('100%')
              .margin({ left: 15 })
              .alignItems(HorizontalAlign.Start)
              .flexGrow(1)
              .justifyContent(FlexAlign.Start)

              // .backgroundColor('#ff0')
            }
            .width('100%')
            .height(100)
            .margin({ bottom: 15 })

            // .backgroundColor('#0f0')

            // 第一组
            Column() {
              List() {
                ListItem() {
                  InfoRow({
                    icon: $r('app.media.ic_bookmark'),
                    title: $r('app.string.app_tags'),
                    info: this.appInfo.tags,
                    showRightArrow: false
                  })
                }

                ListItem() {
                  InfoRow({
                    icon: $r('app.media.ic_app'),
                    title: $r('app.string.app_pkg_name'),
                    info: this.appInfo.packageName,
                    showRightArrow: false
                  })
                }

                ListItem() {
                  InfoRow({
                    icon: $r('app.media.ic_flags'),
                    title: $r('app.string.current_version'),
                    info: this.appInfo.version,
                    showRightArrow: false
                  })
                }

                ListItem() {
                  InfoRow({
                    icon: $r('app.media.ic_laptop'),
                    title: $r('app.string.developer'),
                    info: this.appInfo.vender,
                    showRightArrow: false
                  })
                }

                ListItem() {
                  InfoRow({
                    icon: $r('app.media.ic_link'),
                    title: $r('app.string.repo'),
                    info: this.appInfo.openSourceAddress,
                    clickHandler: () => {
                      router.pushUrl({ url: 'pages/Browser', params: {
                        title: this.appInfo.name,
                        url: this.appInfo.openSourceAddress,
                        params: this.localParams
                      } });
                    }
                  })
                }

                ListItem() {
                  InfoRow({
                    icon: $r('app.media.ic_send'),
                    title: $r('app.string.release_date'),
                    info: this.appInfo.releaseTime,
                    showRightArrow: false
                  })
                }
              }.divider({ strokeWidth: 0.5, color: '#d6d6d6', startMargin: 40, endMargin: 0 })
            }.borderRadius(18).backgroundColor('#ffffff')

          }.width('100%').padding({ left: 15, right: 15 })
        }
        .edgeEffect(EdgeEffect.None)
        .width('100%')
        .height('auto')
        .margin({ bottom: 56 })
      }
      .width('100%')
      .height('100%')
    }.width('100%').height('100%').backgroundColor('#ffffff')
  }
}