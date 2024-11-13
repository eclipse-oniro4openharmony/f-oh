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
import WindowStageUtil from '../utils/WindowStageUtil'
import { HomePage } from './HomePage'
import SettingPage from './SettingPage'
import window from '@ohos.window'
import App from './AppPage';
import { AppType } from '../model/AppInfo'

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController()
  @State currentIndex: number = 0
  @State selectedFontColor: string = '#007DFF'
  @State fontColor: string = '#182431'

  onPageShow() {
    console.info('IndexComponent onPageShow');
    this.changeLFS()
  }

  @Builder
  TabBarBuilder(index: number, title: string | Resource, icon: Resource, iconSelected: Resource) {
    Column() {
      Image(this.currentIndex === index ? iconSelected : icon)
        .width(24)
        .height(24)
        .margin(5)
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontColor(this.currentIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(10)
        .fontWeight(500)
        .lineHeight(14)
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
    .backgroundColor('#f7f7f7')
    .border({ width: { top: 0.5 }, color: '#f8bbbbbb' })
  }

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        controller: this.controller,
        index: this.currentIndex
      }) {
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBarBuilder(0, $r('app.string.home'), $r('app.media.ic_home_normal'), $r('app.media.ic_home_active')))

        TabContent() {
          //  Text('App')
          App({ appType: AppType.APP })
        }
        .tabBar(this.TabBarBuilder(1, $r('app.string.app'), $r('app.media.ic_app_normal'), $r('app.media.ic_app_active')))

        TabContent() {
          App({ appType: AppType.GAME })
        }
        .tabBar(this.TabBarBuilder(2, $r('app.string.game'), $r('app.media.ic_game_normal'), $r('app.media.ic_game_active')))

        TabContent() {
          SettingPage()
        }
        .tabBar(this.TabBarBuilder(3, $r('app.string.settings'), $r('app.media.ic_search_normal'), $r('app.media.ic_search_active')))
      }
      .vertical(false)
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .barHeight(66)
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
  }

  changeLFS() {
    // 从 AppStorage 获取 windowStage 实例
    const windowStage = AppStorage.get<window.WindowStage>("windowStage");

    if (!windowStage) {
      console.error("windowStage is not available in AppStorage.");
      return;
    }

    if (this.currentIndex == 3) {
      WindowStageUtil.setLayoutFullScreen(windowStage, '#f3f4f6', WindowStageUtil.COLOR_BLACK, '#f7f7f7', WindowStageUtil.COLOR_BLACK);
    } else {
      WindowStageUtil.setLayoutFullScreen(windowStage, WindowStageUtil.COLOR_WHITE, WindowStageUtil.COLOR_BLACK, '#f7f7f7', WindowStageUtil.COLOR_BLACK);
    }
  }
}