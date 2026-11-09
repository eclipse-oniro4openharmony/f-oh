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
import { AppCategory, AppInfo } from '../model/AppInfo';
import { catalog, SortMode } from '../data/Catalog';
import { AppRow } from '../components/AppRow';
import { MessageView, PageToolbar } from '../components/Common';
import { ListKind, ListParams } from '../common/Nav';
import { FontSize, Size, Space } from '../common/Theme';
import { AppContext } from '../common/AppContext';

const ALL: number = 100000;

/** "See all" for a Discover section, or every app carrying a tag. */
@ComponentV2
export struct AppListPage {
  @Param @Require params: ListParams;

  title(): ResourceStr {
    switch (this.params.kind) {
      case ListKind.RECENT:
        return $r('app.string.section_recent');
      case ListKind.GAMES:
        return $r('app.string.tab_games');
      case ListKind.FROM_SOURCE:
        return $r('app.string.section_source');
      case ListKind.TAG:
        return this.params.tag;
      default:
        return $r('app.string.section_popular');
    }
  }

  apps(): AppInfo[] {
    switch (this.params.kind) {
      case ListKind.RECENT:
        return catalog.recent(ALL);
      case ListKind.GAMES:
        return catalog.inCategory(AppCategory.GAME, SortMode.POPULAR, '');
      case ListKind.FROM_SOURCE:
        return catalog.builtFromSource(ALL);
      case ListKind.TAG:
        return catalog.withTag(this.params.tag, SortMode.POPULAR);
      default:
        return catalog.popular(ALL);
    }
  }

  build() {
    NavDestination() {
      Column() {
        PageToolbar({ title: this.title() })
        List() {
          ListItem() {
            Text(AppContext.plural($r('app.plural.count_apps'), this.apps().length))
              .fontSize(FontSize.CAPTION)
              .fontColor($r('app.color.text_tertiary'))
              .padding({ left: Space.GUTTER, top: Space.XS, bottom: Space.XS })
          }
          if (this.apps().length === 0) {
            ListItem() {
              MessageView({ symbol: $r('sys.symbol.square_grid_2x2'), title: $r('app.string.empty_list') })
            }
          }
          ForEach(this.apps(), (app: AppInfo) => {
            ListItem() {
              AppRow({ app: app })
            }
          }, (app: AppInfo) => app.packageName)
        }
        .layoutWeight(1)
        .divider({
          strokeWidth: 0.5,
          color: $r('app.color.divider'),
          startMargin: Space.GUTTER + Size.ICON_M + Space.M,
          endMargin: Space.GUTTER
        })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .contentEndOffset(Space.XL)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
  }
}
