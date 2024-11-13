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
import WindowStageUtil from '../utils/WindowStageUtil';
import { SettingRow } from '../components/Settings';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import window from '@ohos.window';

const ToastDuration = 1000
const APP_VERSION = "1.3.5";

@Entry
@Component
struct AboutApp {
  onPageShow() {
    const windowStage = AppStorage.get<window.WindowStage>("windowStage");
    console.info('About app onPageShow');
    WindowStageUtil.setLayoutFullScreen(windowStage, '#f3f4f6', WindowStageUtil.COLOR_BLACK, '#f3f4f6', WindowStageUtil.COLOR_BLACK);
  }

  @Builder
  NavigationTitle() {
    Column() {
      Text($r('app.string.about_foh'))
        .fontColor('#182431')
        .fontSize(26)
        .fontWeight(500)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
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
            this.LogoAndVersionComponent()
            this.AppInfoComponent()
          }.width('100%').padding({ left: 15, right: 15 })
        }
        .edgeEffect(EdgeEffect.None)
        .width('100%')
        .height('auto')
        .margin({ bottom: 56 })
      }
      .width('100%')
      .height('100%')
    }.width('100%').height('100%').backgroundColor('#f3f4f6')

    //    .padding({top: WindowStageUtil.STATUS_BAR_HEIGHT})
  }

  @Builder
  LogoAndVersionComponent() {
    Column() {
      Image($r("app.media.ONIRO"))
        .height(100)
        .width(100)
        .border({ width: 0.7, radius: 16, color: '#ebebeb' })
      Text($r('app.string.EntryAbility_label'))
        .fontSize(18)
        .fontColor('#182431')
        .fontWeight(500)
        .padding({ top: 8 })
      Row() {
        Text($r('app.string.app_version'))
          .fontSize(14)
          .fontColor('#99182431')
          .margin({ top: 4 })
        Text(' ' + APP_VERSION)
          .fontSize(14)
          .fontColor('#99182431')
          .margin({ top: 4 })
      }
    }
    .alignItems(HorizontalAlign.Center)
    .align(Alignment.Top)
    .padding({
      top: 62,
      bottom: 62
    })
  }

  @Builder
  AppInfoComponent() {
    // 第一组
    Column() {
      List() {
        ListItem() {
          SettingRow({
            icon: $r('app.media.ONIRO'),
            title: $r('app.string.oniro_platform'),
            info: 'https://oniroproject.org/',
            clickHandler: () => {
              router.pushUrl({
                url: 'pages/Browser',
                params: { title: $r('app.string.oniro_platform'), url: 'https://oniroproject.org/' }
              });
            }
          })
        }

        ListItem() {
          SettingRow({
            icon: $r('app.media.author_avatar'),
            title: $r('app.string.app_author'),
            info: 'westinyang',
            clickHandler: () => {
              router.pushUrl({ url: 'pages/AboutAuthor', params: {} });
            }
          })
        }

        ListItem() {
          SettingRow({
            icon: $r('app.media.ic_favorite'),
            title: $r('app.string.repo'),
            info: 'https://github.com/eclipse-oniro4openharmony/f-oh',
            clickHandler: () => {
              router.pushUrl({
                url: 'pages/Browser',
                params: { title: $r('app.string.repo'), url: 'https://github.com/eclipse-oniro4openharmony/f-oh' }
              });
            }
          })
        }

        ListItem() {
          SettingRow({
            icon: $r('app.media.ic_eclipse_oniro'),
            title: $r('app.string.community'),
            info: 'https://github.com/orgs/eclipse-oniro4openharmony/repositories',
            clickHandler: () => {
              router.pushUrl({
                url: 'pages/Browser',
                params: {
                  title: $r('app.string.community'),
                  url: 'https://github.com/orgs/eclipse-oniro4openharmony/repositories'
                }
              });
            }
          })
        }
      }.divider({ strokeWidth: 0.5, color: '#d6d6d6', startMargin: 58, endMargin: 14 })
    }.borderRadius(18).backgroundColor('#fff')
  }
}