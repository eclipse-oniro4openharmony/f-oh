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
import { registerAllFonts } from '../font/registerFonts';
import { fonts } from '../font/fonts'
import window from '@ohos.window';

const ToastDuration = 1000
const AUTHOR_NAME = "westinyang"
const AUTHOR_INFO = $r('app.string.indie_dev');

@Entry
@Component
struct AboutAuthor {
  aboutToAppear(){
    registerAllFonts();
  }
  onPageShow() {
    const windowStage = AppStorage.get<window.WindowStage>("windowStage");
    console.info('About author onPageShow');
    WindowStageUtil.setLayoutFullScreen(windowStage, '#f3f4f6', WindowStageUtil.COLOR_BLACK, '#f3f4f6', WindowStageUtil.COLOR_BLACK);
  }

  @Builder NavigationTitle() {
    Column() {
      Text($r('app.string.about_author'))
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
          }.width('100%').padding({left: 15, right: 15})
        }
        .edgeEffect(EdgeEffect.None)
        .width('100%')
        .height('auto')
        .margin({bottom: 56})
      }
      .width('100%')
      .height('100%')
    }.width('100%').height('100%').backgroundColor('#f3f4f6')
    //    .padding({top: WindowStageUtil.STATUS_BAR_HEIGHT})
  }

  @Builder LogoAndVersionComponent() {
    Column() {
      Image($r("app.media.author_avatar"))
        .height(72)
        .width(72)
        .border({width: 0.7, radius: 36, color: '#ebebeb'})
      Text(AUTHOR_NAME)
        .fontSize(18)
        .fontColor('#182431')
        .fontWeight(500)
        .padding({ top: 8 })
      // todo: 不明白为什么会出现乱码
        //.fontFamily(fonts.semi_bold.familyName)

      Text(AUTHOR_INFO)
        .fontSize(14)
        .fontColor('#99182431')
        .margin({top: 4})
      // todo: 不明白为什么会出现乱码
        //.fontFamily(fonts.regular.familyName)
    }
    .alignItems(HorizontalAlign.Center)
    .align(Alignment.Top)
    .padding({
      top: 62,
      bottom: 62
    })
  }

  @Builder AppInfoComponent() {
    // 第一组
    Column() {
      List() {
        ListItem() { SettingRow({icon: $r('app.media.ic_laptop'), title: 'I\'m westinyang', info: 'https://kaihongpai.feishu.cn/wiki/...', clickHandler: ()=> {
          router.pushUrl({ url: 'pages/Browser', params: {title: 'I\'m westinyang', url: 'https://kaihongpai.feishu.cn/wiki/CqWLwJRadibxztkrIWZcogWxnXd'} });
        }}) }
        ListItem() { SettingRow({icon: $r('app.media.ic_gitee'), title: 'Gitee', info: 'https://gitee.com/westinyang', clickHandler: ()=> {
          router.pushUrl({ url: 'pages/Browser', params: {title: 'Gitee', url: 'https://gitee.com/westinyang'} });
        }}) }
        ListItem() { SettingRow({icon: $r('app.media.ic_github'), title: 'Github', info: 'https://github.com/westinyang', clickHandler: ()=> {
          router.pushUrl({ url: 'pages/Browser', params: {title: 'Github', url: 'https://github.com/westinyang'} });
        }}) }
        ListItem() { SettingRow({icon: $r('app.media.ic_bilibili'), title: 'Bilibili', info: 'https://space.bilibili.com/74433635', clickHandler: ()=> {
          router.pushUrl({ url: 'pages/Browser', params: {title: 'Bilibili', url: 'https://space.bilibili.com/74433635'} });
        }}) }
      }.divider({ strokeWidth: 0.5, color: '#d6d6d6', startMargin: 58, endMargin: 14 })
    }.borderRadius(18).backgroundColor('#fff')
  }
}