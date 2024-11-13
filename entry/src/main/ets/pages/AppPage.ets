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
import { AppInfo, AppType } from '../model/AppInfo';
import AppListItem from '../components/AppListItem';
import { DataSource } from '../data/DataSource';
import hilog from '@ohos.hilog';
import { HttpErrorComponent, LoadComponent } from './Browser';

@Component
export default struct App {
  @State httpCode: number = 0 // 定义一个状态变量用于保存 HTTP 响应码
  appType: AppType = AppType.APP
  @State appList: AppInfo[] = []
  @State isLoading: boolean = false

  aboutToAppear() {
    this.isLoading = true;
    const source = new DataSource()
    source.fetchHttpCode().then((code) => {
      this.httpCode = code; // 更新状态变量以触发 UI 的重新渲染
      if (code == 200) {
        DataSource.getAppList(this.appType, (data: AppInfo[]) => {
          this.appList = data;
          this.isLoading = false;
        })
      }
      else {
        this.isLoading = false;
      }
    });
  }

  @Builder
  NavigationTitle() {
    Column() {
      Text(this.appType == AppType.APP ? $r('app.string.app') : $r('app.string.game'))
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
          .hideBackButton(true)
          .border({ width: { bottom: 0.5 }, color: '#c9c9c9' })
          .padding({ left: 15, right: 15 })
        // 根据 isLoading 状态条件渲染 loadComponent 或 Scroll
        if (this.isLoading) {
          LoadComponent() // 显示加载组件
        }
        //bad http response
        if (this.httpCode == -1) {
          HttpErrorComponent({
            text: 'Can\'t connect to the server'
          })
        }

        Scroll() {
          Column() {
            List({ space: 0, initialIndex: 0 }) {
              ForEach(this.appList, (item: AppInfo) => {
                ListItem() {
                  AppListItem({ appInfo: item })
                }
              }, (item: AppInfo, index) => index + JSON.stringify(item))
            }
            .width('auto')
            .height('auto')
            .padding({ left: 15, right: 15 })
            .divider({
              strokeWidth: 0.5,
              color: '#d6d6d6',
              startMargin: 65,
              endMargin: 0
            })
          }
          .width('100%')

          //          .margin({top: 7.5, bottom: 7.5})
        }
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height('auto')
        .margin({ bottom: 56 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
