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
import { AppCategory, AppInfo } from '../../model/AppInfo';
import { catalog, LoadState, SortMode, TagCount } from '../../data/Catalog';
import { AppRow } from '../../components/AppRow';
import { Chip, ErrorView, MessageView, SkeletonRows, TabHeader } from '../../components/Common';
import { FontSize, Size, Space } from '../../common/Theme';
import { AppContext } from '../../common/AppContext';

const MAX_TAG_CHIPS: number = 12;

export function sortLabel(mode: SortMode): Resource {
  if (mode === SortMode.RECENT) {
    return $r('app.string.sort_recent');
  }
  if (mode === SortMode.NAME) {
    return $r('app.string.sort_name');
  }
  return $r('app.string.sort_popular');
}

/** The Apps and Games tabs: every app of one category, sortable and filterable by tag. */
@ComponentV2
export struct CategoryTab {
  @Param category: string = AppCategory.APP;
  @Local sort: SortMode = SortMode.POPULAR;
  @Local tag: string = '';
  @Local pulling: boolean = false;
  @Local sortMenuShown: boolean = false;

  title(): Resource {
    return this.category === AppCategory.GAME ? $r('app.string.tab_games') : $r('app.string.tab_apps');
  }

  build() {
    Column() {
      TabHeader({ title: this.title() })
      if (catalog.state === LoadState.READY) {
        this.FilterBar()
      }
      Refresh({ refreshing: $$this.pulling }) {
        if (catalog.state === LoadState.READY) {
          this.Results()
        } else if (catalog.state === LoadState.ERROR) {
          Scroll() {
            ErrorView({ onRetry: () => catalog.load(true) })
          }
          .height('100%')
        } else {
          Scroll() {
            SkeletonRows({ count: 8 })
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

  @Builder
  FilterBar() {
    Scroll() {
      Row({ space: Space.S }) {
        // The chip handles its own tap, so the menu is opened through state.
        Chip({
          label: sortLabel(this.sort),
          selected: false,
          trailingSymbol: $r('sys.symbol.chevron_down'),
          onTap: () => this.sortMenuShown = true
        })
          .bindMenu(this.sortMenuShown, [
            { value: $r('app.string.sort_popular'), action: () => this.sort = SortMode.POPULAR },
            { value: $r('app.string.sort_recent'), action: () => this.sort = SortMode.RECENT },
            { value: $r('app.string.sort_name'), action: () => this.sort = SortMode.NAME }
          ], {
            onDisappear: () => this.sortMenuShown = false
          })
        Divider()
          .vertical(true)
          .height(20)
          .strokeWidth(1)
          .color($r('app.color.divider'))
        Chip({ label: $r('app.string.filter_all'), selected: this.tag === '', onTap: () => this.tag = '' })
        ForEach(catalog.tags(this.category, 1).slice(0, MAX_TAG_CHIPS), (t: TagCount) => {
          Chip({ label: t.name, selected: this.tag === t.name, onTap: () => this.tag = t.name })
        }, (t: TagCount) => t.name)
      }
      .padding({ left: Space.GUTTER, right: Space.GUTTER })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(46)
  }

  apps(): AppInfo[] {
    return catalog.inCategory(this.category, this.sort, this.tag);
  }

  // Reads sort and tag itself: @Builder arguments are evaluated once, not tracked.
  @Builder
  Results() {
    List() {
      ListItem() {
        Text(AppContext.plural(this.category === AppCategory.GAME ? $r('app.plural.count_games') :
        $r('app.plural.count_apps'), this.apps().length))
          .fontSize(FontSize.CAPTION)
          .fontColor($r('app.color.text_tertiary'))
          .padding({ left: Space.GUTTER, top: Space.S, bottom: Space.XS })
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
    .width('100%')
    .height('100%')
    .divider({
      strokeWidth: 0.5,
      color: $r('app.color.divider'),
      startMargin: Space.GUTTER + Size.ICON_M + Space.M,
      endMargin: Space.GUTTER
    })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .contentEndOffset(Space.XL)
  }
}
