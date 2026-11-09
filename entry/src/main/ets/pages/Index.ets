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
import { AppCategory } from '../model/AppInfo';
import { catalog, LoadState } from '../data/Catalog';
import { installManager } from '../data/InstallManager';
import { DetailParams, ListParams, navStack, Routes, WebParams } from '../common/Nav';
import { FontSize, Size } from '../common/Theme';
import { DiscoverTab } from './tabs/DiscoverTab';
import { CategoryTab } from './tabs/CategoryTab';
import { LibraryTab } from './tabs/LibraryTab';
import { AppDetailPage } from './AppDetailPage';
import { SearchPage } from './SearchPage';
import { AppListPage } from './AppListPage';
import { SettingsPage } from './SettingsPage';
import { AboutPage } from './AboutPage';
import { WebPage } from './WebPage';

const TAB_DISCOVER: number = 0;
const TAB_APPS: number = 1;
const TAB_LIBRARY: number = 3;

@Entry
@ComponentV2
struct Index {
  @Local currentTab: number = TAB_DISCOVER;
  private tabs: TabsController = new TabsController();

  aboutToAppear(): void {
    catalog.load(false);
  }

  onPageShow(): void {
    // Back from the background: apps may have been installed or removed meanwhile.
    if (catalog.state === LoadState.READY) {
      installManager.sync(catalog.apps);
    }
  }

  updateCount(): number {
    return installManager.updateCount(catalog.apps);
  }

  @Builder
  RouteMap(name: string, param: Object) {
    if (name === Routes.DETAIL) {
      AppDetailPage({ params: param as DetailParams })
    } else if (name === Routes.SEARCH) {
      SearchPage()
    } else if (name === Routes.LIST) {
      AppListPage({ params: param as ListParams })
    } else if (name === Routes.SETTINGS) {
      SettingsPage()
    } else if (name === Routes.ABOUT) {
      AboutPage()
    } else if (name === Routes.WEB) {
      WebPage({ params: param as WebParams })
    }
  }

  @Builder
  TabItem(index: number, title: Resource, symbol: Resource, selectedSymbol: Resource) {
    Column({ space: 2 }) {
      Badge({
        // Read here, not passed in: @Builder arguments are evaluated once.
        count: index === TAB_LIBRARY ? this.updateCount() : 0,
        maxCount: 99,
        position: BadgePosition.RightTop,
        style: { badgeSize: 16, fontSize: 10, badgeColor: $r('app.color.magenta') }
      }) {
        SymbolGlyph(this.currentTab === index ? selectedSymbol : symbol)
          .fontSize(24)
          .fontColor([this.currentTab === index ? $r('app.color.brand') : $r('app.color.tab_inactive')])
          .padding(2)
      }

      Text(title)
        .fontSize(FontSize.CAPTION - 1)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentTab === index ? $r('app.color.brand') : $r('app.color.tab_inactive'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Navigation(navStack) {
      Tabs({ barPosition: BarPosition.End, controller: this.tabs, index: this.currentTab }) {
        TabContent() {
          DiscoverTab({ onOpenLibrary: () => this.tabs.changeIndex(TAB_LIBRARY) })
        }
        .tabBar(this.TabItem(TAB_DISCOVER, $r('app.string.tab_discover'), $r('sys.symbol.house'),
          $r('sys.symbol.house_fill')))

        TabContent() {
          CategoryTab({ category: AppCategory.APP })
        }
        .tabBar(this.TabItem(TAB_APPS, $r('app.string.tab_apps'), $r('sys.symbol.square_grid_2x2'),
          $r('sys.symbol.square_grid_2x2')))

        TabContent() {
          CategoryTab({ category: AppCategory.GAME })
        }
        .tabBar(this.TabItem(2, $r('app.string.tab_games'), $r('sys.symbol.gamecontroller'),
          $r('sys.symbol.gamecontroller_fill')))

        TabContent() {
          LibraryTab({ onBrowse: () => this.tabs.changeIndex(TAB_APPS) })
        }
        .tabBar(this.TabItem(TAB_LIBRARY, $r('app.string.tab_library'), $r('sys.symbol.archivebox'),
          $r('sys.symbol.archivebox_fill')))
      }
      .barHeight(Size.TAB_BAR)
      .barMode(BarMode.Fixed)
      .barBackgroundColor($r('app.color.tab_bar'))
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .scrollable(false)
      .animationDuration(0)
      .onChange((index: number) => {
        this.currentTab = index;
      })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
    .navDestination(this.RouteMap)
    .backgroundColor($r('app.color.bg'))
  }
}
