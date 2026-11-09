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
import { AppInfo } from '../model/AppInfo';
import { catalog, LoadState, TagCount } from '../data/Catalog';
import { SearchHistory } from '../data/SearchHistory';
import { AppRow } from '../components/AppRow';
import { Chip, ErrorView, IconButton, MessageView, SkeletonRows } from '../components/Common';
import { Nav } from '../common/Nav';
import { FontSize, Radius, Size, Space } from '../common/Theme';
import { AppContext } from '../common/AppContext';

const FIELD_ID: string = 'store_search_field';
const SUGGESTED_TAGS: number = 10;
const SUGGESTED_APPS: number = 5;

/** Instant search over the whole catalogue: names, developers, tags and package names. */
@ComponentV2
export struct SearchPage {
  @Local query: string = '';
  @Local recent: string[] = [];
  private controller: SearchController = new SearchController();
  private focusedOnce: boolean = false;

  aboutToAppear(): void {
    this.recent = SearchHistory.load();
    catalog.load(false);
  }

  aboutToDisappear(): void {
    // Leaving with results on screen counts as a search worth remembering.
    if (this.query.trim() !== '' && catalog.search(this.query).length > 0) {
      SearchHistory.add(this.query);
    }
  }

  setQuery(q: string): void {
    this.query = q;
    this.controller.caretPosition(q.length);
  }

  build() {
    NavDestination() {
      Column() {
        Row({ space: Space.XS }) {
          IconButton({ symbol: $r('sys.symbol.chevron_left'), onTap: () => Nav.back() })
          Search({ value: this.query, placeholder: $r('app.string.search_hint'), controller: this.controller })
            .id(FIELD_ID)
            .layoutWeight(1)
            .height(42)
            .borderRadius(Radius.PILL)
            .backgroundColor($r('app.color.surface_variant'))
            .placeholderColor($r('app.color.text_tertiary'))
            .placeholderFont({ size: FontSize.BODY })
            .textFont({ size: FontSize.BODY })
            .fontColor($r('app.color.text_primary'))
            .caretStyle({ color: $r('app.color.brand') })
            .enterKeyType(EnterKeyType.Search)
            .onChange((value: string) => {
              this.query = value;
            })
            .onSubmit((value: string) => {
              this.recent = SearchHistory.add(value);
            })
        }
        .width('100%')
        .height(Size.TOOLBAR)
        .padding({ left: Space.XS, right: Space.GUTTER })

        if (catalog.state === LoadState.ERROR) {
          ErrorView({ onRetry: () => catalog.load(true) })
        } else if (catalog.state !== LoadState.READY) {
          SkeletonRows({ count: 6 })
        } else if (this.query.trim() === '') {
          this.Suggestions()
        } else {
          this.Results()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onHidden(() => {
      // Leaving for a result: drop focus so the keyboard stays down on return.
      try {
        this.getUIContext().getFocusController().clearFocus();
      } catch (err) {
        // Focus is a convenience.
      }
    })
    .onShown(() => {
      // Only on arrival: coming back from a result must not pop the keyboard up again.
      if (this.focusedOnce) {
        return;
      }
      this.focusedOnce = true;
      try {
        this.getUIContext().getFocusController().requestFocus(FIELD_ID);
      } catch (err) {
        // Focus is a convenience.
      }
    })
  }

  @Builder
  Heading(title: Resource) {
    Text(title)
      .fontSize(FontSize.BODY_S)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_secondary'))
  }

  @Builder
  Suggestions() {
    Scroll() {
      Column({ space: Space.S }) {
        if (this.recent.length > 0) {
          Row() {
            this.Heading($r('app.string.search_recent'))
            Blank()
            Text($r('app.string.clear'))
              .fontSize(FontSize.BODY_S)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.brand'))
              .padding({ top: Space.XS, bottom: Space.XS, left: Space.S })
              .onClick(() => {
                this.recent = SearchHistory.clear();
              })
          }
          .width('100%')
          .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.M })

          ForEach(this.recent, (q: string) => {
            Row({ space: Space.M }) {
              SymbolGlyph($r('sys.symbol.clock'))
                .fontSize(18)
                .fontColor([$r('app.color.text_tertiary')])
              Text(q)
                .fontSize(FontSize.BODY)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              SymbolGlyph($r('sys.symbol.arrow_up_right'))
                .fontSize(16)
                .fontColor([$r('app.color.text_tertiary')])
            }
            .width('100%')
            .height(44)
            .padding({ left: Space.GUTTER, right: Space.GUTTER })
            .onClick(() => this.setQuery(q))
          }, (q: string) => q)
        }

        if (catalog.tags('', 1).length > 0) {
          Column({ space: Space.S }) {
            this.Heading($r('app.string.search_suggested'))
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(catalog.tags('', 1).slice(0, SUGGESTED_TAGS), (t: TagCount) => {
                Chip({ label: t.name, onTap: () => this.setQuery(t.name) })
                  .margin({ right: Space.S, bottom: Space.S })
              }, (t: TagCount) => t.name)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.L })
        }

        Column() {
          Text($r('app.string.section_popular'))
            .fontSize(FontSize.BODY_S)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: Space.GUTTER, top: Space.M })
          ForEach(catalog.popular(SUGGESTED_APPS), (app: AppInfo) => {
            AppRow({ app: app })
          }, (app: AppInfo) => app.packageName)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: Space.XXL })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  results(): AppInfo[] {
    return catalog.search(this.query);
  }

  // Reads this.query itself: @Builder arguments are evaluated once, not tracked.
  @Builder
  Results() {
    if (this.results().length === 0) {
      MessageView({
        symbol: $r('sys.symbol.magnifyingglass'),
        title: AppContext.str($r('app.string.empty_search_title'), this.query.trim()),
        body: $r('app.string.empty_search_body')
      })
    } else {
      List() {
        ListItem() {
          Text(AppContext.plural($r('app.plural.count_results'), this.results().length))
            .fontSize(FontSize.CAPTION)
            .fontColor($r('app.color.text_tertiary'))
            .padding({ left: Space.GUTTER, top: Space.S, bottom: Space.XS })
        }
        ForEach(this.results(), (app: AppInfo) => {
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
      .contentEndOffset(Space.XL)
    }
  }
}
