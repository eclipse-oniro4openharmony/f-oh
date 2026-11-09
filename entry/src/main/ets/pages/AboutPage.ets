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
import { CardRow, cardTitle, PageToolbar } from '../components/Common';
import { Nav } from '../common/Nav';
import { COMMUNITY_URL, FontSize, ONIRO_URL, Radius, SOURCE_URL, Space, UPSTREAM_URL } from '../common/Theme';
import { AppContext } from '../common/AppContext';
import { selfVersion } from './SettingsPage';

@Styles
function card() {
  .backgroundColor($r('app.color.surface'))
  .borderRadius(Radius.L)
  .margin({ left: Space.GUTTER, right: Space.GUTTER })
}

@ComponentV2
export struct AboutPage {
  private version: string = selfVersion();

  build() {
    NavDestination() {
      Column() {
        PageToolbar({ title: $r('app.string.about_title') })
        Scroll() {
          Column() {
            Column({ space: Space.S }) {
              Image($r('app.media.store_icon'))
                .width(88)
                .height(88)
                .borderRadius(22)
                .shadow({ radius: 24, color: '#336024B5', offsetY: 8 })
              Text($r('app.string.EntryAbility_label'))
                .fontSize(FontSize.HEADLINE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .margin({ top: Space.S })
              if (this.version !== '') {
                Text(AppContext.str($r('app.string.about_version'), this.version))
                  .fontSize(FontSize.BODY_S)
                  .fontColor($r('app.color.text_secondary'))
              }
              Text($r('app.string.about_tagline'))
                .fontSize(FontSize.BODY)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
                .margin({ top: Space.XS })
            }
            .width('100%')
            .padding({ left: Space.XXL, right: Space.XXL, top: Space.XL, bottom: Space.S })

            cardTitle($r('app.string.about_links'))
            Column() {
              CardRow({
                symbol: $r('sys.symbol.code'),
                title: $r('app.string.about_source'),
                value: 'GitHub',
                chevron: true,
                onTap: () => Nav.openWeb(AppContext.str($r('app.string.about_source')), SOURCE_URL)
              })
              CardRow({
                symbol: $r('sys.symbol.compass'),
                title: $r('app.string.about_oniro'),
                value: 'oniroproject.org',
                chevron: true,
                onTap: () => Nav.openWeb(AppContext.str($r('app.string.about_oniro')), ONIRO_URL)
              })
              CardRow({
                symbol: $r('sys.symbol.person_2'),
                title: $r('app.string.about_community'),
                chevron: true,
                showDivider: false,
                onTap: () => Nav.openWeb(AppContext.str($r('app.string.about_community')), COMMUNITY_URL)
              })
            }
            .card()

            cardTitle($r('app.string.about_credits'))
            Column() {
              CardRow({
                symbol: $r('sys.symbol.heart'),
                symbolColor: $r('app.color.magenta'),
                title: $r('app.string.about_based_on'),
                chevron: true,
                onTap: () => Nav.openWeb('westinyang', UPSTREAM_URL)
              })
              CardRow({
                symbol: $r('sys.symbol.doc_text'),
                title: $r('app.string.about_license'),
                value: 'GPL-3.0',
                showDivider: false
              })
            }
            .card()
          }
          .width('100%')
          .padding({ bottom: Space.XXL })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
  }
}
