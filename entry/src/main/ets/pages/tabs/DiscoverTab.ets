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
import { AppInfo } from '../../model/AppInfo';
import { catalog, LoadState, TagCount } from '../../data/Catalog';
import { installManager, Phase } from '../../data/InstallManager';
import { AppCard, AppRow } from '../../components/AppRow';
import { Chip, ErrorView, IconButton, SectionHeader, SkeletonRows } from '../../components/Common';
import { ListKind, Nav } from '../../common/Nav';
import { FontSize, Radius, Space } from '../../common/Theme';
import { AppContext } from '../../common/AppContext';

const ROWS_PER_PAGE: number = 3;
const CAROUSEL_LIMIT: number = 12;

class AppPage {
  key: string = '';
  apps: AppInfo[] = [];
}

function pages(apps: AppInfo[], size: number): AppPage[] {
  const out: AppPage[] = [];
  for (let i = 0; i < apps.length; i += size) {
    const p: AppPage = new AppPage();
    p.apps = apps.slice(i, i + size);
    p.key = p.apps.map((a: AppInfo) => a.packageName).join('|');
    out.push(p);
  }
  return out;
}

@ComponentV2
export struct DiscoverTab {
  @Event onOpenLibrary: () => void = () => {
  };
  @Local pulling: boolean = false;

  updateCount(): number {
    return catalog.apps.filter((a: AppInfo) => installManager.stateOf(a.packageName).phase === Phase.UPDATABLE).length;
  }

  build() {
    Refresh({ refreshing: $$this.pulling }) {
      Scroll() {
        Column() {
          this.Hero()
          if (catalog.state === LoadState.READY) {
            this.Sections()
          } else if (catalog.state === LoadState.ERROR) {
            ErrorView({ onRetry: () => catalog.load(true) })
          } else {
            Column().height(Space.L)
            SkeletonRows({ count: 6 })
          }
        }
        .width('100%')
        .padding({ bottom: Space.XXL })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .onRefreshing(() => {
      catalog.load(true).then((ok: boolean) => {
        this.pulling = false;
        if (!ok) {
          AppContext.toast($r('app.string.network_error'));
        }
      });
    })
    .backgroundColor($r('app.color.bg'))
  }

  @Builder
  Hero() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Soft glows in the Oniro accent colours (magenta #FF27B7, cyan #00C9E5).
      Column()
        .width(300)
        .height(300)
        .radialGradient({ center: [150, 150], radius: 150, colors: [['#66FF27B7', 0.0], ['#00FF27B7', 1.0]] })
        .position({ right: -110, top: -130 })
      Column()
        .width(260)
        .height(260)
        .radialGradient({ center: [130, 130], radius: 130, colors: [['#4D00C9E5', 0.0], ['#0000C9E5', 1.0]] })
        .position({ left: -110, bottom: -140 })

      Column({ space: Space.S }) {
        Row({ space: Space.S }) {
          Image($r('app.media.store_icon'))
            .width(28)
            .height(28)
            .borderRadius(7)
          Text($r('app.string.hero_eyebrow'))
            .fontSize(FontSize.BODY_S)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.on_hero_secondary'))
            .layoutWeight(1)
          IconButton({
            symbol: $r('sys.symbol.gearshape'),
            color: $r('app.color.on_hero'),
            buttonSize: 36,
            symbolSize: 20,
            onTap: () => Nav.openSettings()
          })
        }
        .width('100%')

        Text($r('app.string.hero_title'))
          .fontSize(FontSize.HEADLINE + 4)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.on_hero'))
          .margin({ top: Space.S })
        if (catalog.apps.length > 0) {
          Text(AppContext.plural($r('app.plural.hero_subtitle'), catalog.apps.length))
            .fontSize(FontSize.BODY)
            .fontColor($r('app.color.on_hero_secondary'))
        }

        // Search entry: opens the search page.
        Row({ space: Space.S }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(20)
            .fontColor([$r('app.color.text_secondary')])
          Text($r('app.string.search_hint'))
            .fontSize(FontSize.BODY)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
        }
        .width('100%')
        .height(46)
        .padding({ left: Space.L, right: Space.L })
        .borderRadius(Radius.PILL)
        .backgroundColor($r('app.color.surface'))
        .margin({ top: Space.M })
        .onClick(() => Nav.openSearch())

        if (this.updateCount() > 0) {
          Row({ space: Space.S }) {
            SymbolGlyph($r('sys.symbol.arrow_up_circle_fill'))
              .fontSize(18)
              .fontColor([$r('app.color.on_hero')])
            Text(AppContext.plural($r('app.plural.hero_updates'), this.updateCount()))
              .fontSize(FontSize.BODY_S)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.on_hero'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.on_hero')])
          }
          .width('100%')
          .height(40)
          .padding({ left: Space.M, right: Space.M })
          .borderRadius(Radius.PILL)
          .backgroundColor('#33FFFFFF')
          .margin({ top: Space.XS })
          .onClick(() => this.onOpenLibrary())
        }
      }
      .width('100%')
      .padding({ left: Space.L + 4, right: Space.S, top: Space.M, bottom: Space.L + 4 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('auto')
    .margin({ left: Space.GUTTER, right: Space.GUTTER, top: Space.S })
    .borderRadius(Radius.XL)
    .clip(true)
    .linearGradient({
      angle: 135,
      colors: [[$r('app.color.hero_start'), 0.0], [$r('app.color.hero_end'), 1.0]]
    })
  }

  @Builder
  Sections() {
    Column() {
      SectionHeader({ title: $r('app.string.section_popular'), onSeeAll: () => Nav.openList(ListKind.POPULAR, '') })
      List({ space: Space.M }) {
        ForEach(pages(catalog.popular(ROWS_PER_PAGE * 4), ROWS_PER_PAGE), (page: AppPage) => {
          ListItem() {
            Column() {
              ForEach(page.apps, (app: AppInfo) => {
                AppRow({ app: app, horizontalPadding: 0 })
              }, (app: AppInfo) => app.packageName)
            }
          }
          .width('88%')
        }, (page: AppPage) => page.key)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .scrollSnapAlign(ScrollSnapAlign.START)
      .contentStartOffset(Space.GUTTER)
      .contentEndOffset(Space.GUTTER)
      .edgeEffect(EdgeEffect.Spring)
      .height(ROWS_PER_PAGE * 80)
      .width('100%')

      this.Carousel($r('app.string.section_recent'), ListKind.RECENT)
      this.Carousel($r('app.string.section_games'), ListKind.GAMES)
      this.Carousel($r('app.string.section_source'), ListKind.FROM_SOURCE)

      if (catalog.tags('', 2).length > 0) {
        SectionHeader({ title: $r('app.string.section_tags'), showAll: false })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(catalog.tags('', 2), (tag: TagCount) => {
            Chip({ label: tag.name, onTap: () => Nav.openList(ListKind.TAG, tag.name) })
              .margin({ right: Space.S, bottom: Space.S })
          }, (tag: TagCount) => tag.name)
        }
        .padding({ left: Space.GUTTER, right: Space.GUTTER })
      }
    }
    .width('100%')
  }

  carouselApps(kind: ListKind): AppInfo[] {
    if (kind === ListKind.GAMES) {
      return catalog.games(CAROUSEL_LIMIT);
    }
    if (kind === ListKind.FROM_SOURCE) {
      return catalog.builtFromSource(CAROUSEL_LIMIT);
    }
    return catalog.recent(CAROUSEL_LIMIT);
  }

  // Takes the kind, not the apps: @Builder arguments are evaluated once.
  @Builder
  Carousel(title: Resource, kind: ListKind) {
    if (this.carouselApps(kind).length > 0) {
      SectionHeader({ title: title, onSeeAll: () => Nav.openList(kind, '') })
      List({ space: Space.L }) {
        ForEach(this.carouselApps(kind), (app: AppInfo) => {
          ListItem() {
            AppCard({ app: app })
          }
        }, (app: AppInfo) => app.packageName)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .contentStartOffset(Space.GUTTER)
      .contentEndOffset(Space.GUTTER)
      .edgeEffect(EdgeEffect.Spring)
      .height(152)
      .width('100%')
    }
  }
}
