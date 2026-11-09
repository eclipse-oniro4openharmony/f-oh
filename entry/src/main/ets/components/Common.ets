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
import { FontSize, Radius, Size, Space } from '../common/Theme';
import { Nav } from '../common/Nav';

/** A round, borderless button around a system symbol. */
@ComponentV2
export struct IconButton {
  @Param symbol: Resource = $r('sys.symbol.xmark');
  @Param color: ResourceColor = $r('app.color.text_primary');
  @Param fill: ResourceColor = Color.Transparent;
  @Param buttonSize: number = Size.TOUCH;
  @Param symbolSize: number = 22;
  @Event onTap: () => void = () => {
  };

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph(this.symbol)
        .fontSize(this.symbolSize)
        .fontColor([this.color])
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .backgroundColor(this.fill)
    .onClick(() => this.onTap())
  }
}

/** Large title at the top of a tab, with search and settings shortcuts. */
@ComponentV2
export struct TabHeader {
  @Param title: ResourceStr = '';
  @Param showSearch: boolean = true;

  build() {
    Row({ space: Space.XS }) {
      Text(this.title)
        .fontSize(FontSize.DISPLAY)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
      if (this.showSearch) {
        IconButton({ symbol: $r('sys.symbol.magnifyingglass'), onTap: () => Nav.openSearch() })
      }
      IconButton({ symbol: $r('sys.symbol.gearshape'), onTap: () => Nav.openSettings() })
    }
    .width('100%')
    .height(Size.TOOLBAR + 8)
    .padding({ left: Space.GUTTER, right: Space.S })
  }
}

/** Top bar of a pushed page: back button, title and an optional trailing action. */
@ComponentV2
export struct PageToolbar {
  @Param title: ResourceStr = '';
  @Param trailingSymbol: Resource | undefined = undefined;
  @Event onTrailing: () => void = () => {
  };

  build() {
    Row({ space: Space.XS }) {
      IconButton({ symbol: $r('sys.symbol.chevron_left'), onTap: () => Nav.back() })
      Text(this.title)
        .fontSize(FontSize.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (this.trailingSymbol !== undefined) {
        IconButton({ symbol: this.trailingSymbol, onTap: () => this.onTrailing() })
      }
    }
    .width('100%')
    .height(Size.TOOLBAR)
    .padding({ left: Space.XS, right: Space.XS })
  }
}

@ComponentV2
export struct SectionHeader {
  @Param title: ResourceStr = '';
  @Param showAll: boolean = true;
  @Event onSeeAll: () => void = () => {
  };

  build() {
    Row() {
      Text(this.title)
        .fontSize(FontSize.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
      if (this.showAll) {
        Row({ space: 2 }) {
          Text($r('app.string.see_all'))
            .fontSize(FontSize.BODY_S)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.brand'))
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor([$r('app.color.brand')])
        }
        .padding({ left: Space.S, top: Space.XS, bottom: Space.XS })
        .onClick(() => this.onSeeAll())
      }
    }
    .width('100%')
    .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.XL, bottom: Space.S })
  }
}

/** A pill; filled with the brand colour when selected. */
@ComponentV2
export struct Chip {
  @Param label: ResourceStr = '';
  @Param selected: boolean = false;
  @Param trailingSymbol: Resource | undefined = undefined;
  @Event onTap: () => void = () => {
  };

  build() {
    Row({ space: 4 }) {
      Text(this.label)
        .fontSize(FontSize.BODY_S)
        .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.selected ? $r('app.color.on_brand') : $r('app.color.text_primary'))
        .maxLines(1)
      if (this.trailingSymbol !== undefined) {
        SymbolGlyph(this.trailingSymbol)
          .fontSize(12)
          .fontColor([this.selected ? $r('app.color.on_brand') : $r('app.color.text_secondary')])
      }
    }
    .height(34)
    .padding({ left: 14, right: 14 })
    .borderRadius(Radius.PILL)
    .backgroundColor(this.selected ? $r('app.color.brand') : $r('app.color.surface_variant'))
    .onClick(() => this.onTap())
  }
}

/** Grey placeholders shaped like app rows, shown while the catalogue loads. */
@ComponentV2
export struct SkeletonRows {
  @Param count: number = 6;

  build() {
    Column() {
      ForEach(Array.from<number>({ length: this.count }), (_: number, i: number) => {
        Row({ space: Space.M }) {
          Column()
            .width(Size.ICON_M)
            .height(Size.ICON_M)
            .borderRadius(14)
            .backgroundColor($r('app.color.skeleton'))
          Column({ space: Space.S }) {
            Column().width('55%').height(14).borderRadius(7).backgroundColor($r('app.color.skeleton'))
            Column().width('35%').height(11).borderRadius(6).backgroundColor($r('app.color.skeleton'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Column()
            .width(Size.ACTION_W - 8)
            .height(Size.ACTION_H)
            .borderRadius(Radius.PILL)
            .backgroundColor($r('app.color.skeleton'))
        }
        .width('100%')
        .padding({ left: Space.GUTTER, right: Space.GUTTER, top: 10, bottom: 10 })
        .opacity(1 - i * 0.12)
      }, (_: number, i: number) => i.toString())
    }
    .width('100%')
  }
}

/** Full-area message with an icon, an explanation and an optional action. */
@ComponentV2
export struct MessageView {
  @Param symbol: Resource = $r('sys.symbol.info_circle');
  @Param title: ResourceStr = '';
  @Param body: ResourceStr = '';
  @Param actionLabel: ResourceStr = '';
  @Event onAction: () => void = () => {
  };

  build() {
    Column({ space: Space.S }) {
      Stack() {
        SymbolGlyph(this.symbol)
          .fontSize(36)
          .fontColor([$r('app.color.brand')])
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor($r('app.color.brand_soft'))
      .margin({ bottom: Space.S })

      Text(this.title)
        .fontSize(FontSize.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
      Text(this.body)
        .fontSize(FontSize.BODY)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
      if (this.actionLabel !== '') {
        Button(this.actionLabel, { type: ButtonType.Capsule })
          .height(40)
          .padding({ left: Space.XL, right: Space.XL })
          .fontSize(FontSize.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.on_brand'))
          .backgroundColor($r('app.color.brand'))
          .margin({ top: Space.M })
          .onClick(() => this.onAction())
      }
    }
    .width('100%')
    .padding({ left: Space.XXL, right: Space.XXL, top: 64, bottom: 64 })
    .justifyContent(FlexAlign.Center)
  }
}

/** The catalogue failed to load and there is nothing to show. */
@ComponentV2
export struct ErrorView {
  @Event onRetry: () => void = () => {
  };

  build() {
    MessageView({
      symbol: $r('sys.symbol.wifi_slash'),
      title: $r('app.string.error_title'),
      body: $r('app.string.error_body'),
      actionLabel: $r('app.string.action_retry'),
      onAction: () => this.onRetry()
    })
  }
}

/** Small heading above a card of rows. */
@Builder
export function cardTitle(title: ResourceStr) {
  Text(title)
    .fontSize(FontSize.BODY_S)
    .fontWeight(FontWeight.Medium)
    .fontColor($r('app.color.text_secondary'))
    .width('100%')
    .padding({ left: Space.GUTTER + Space.XS, right: Space.GUTTER, top: Space.XL, bottom: Space.S })
}

/** One line of a card: icon, title, optional detail, optional chevron. */
@ComponentV2
export struct CardRow {
  @Param symbol: Resource | undefined = undefined;
  @Param symbolColor: ResourceColor = $r('app.color.brand');
  @Param title: ResourceStr = '';
  @Param detail: ResourceStr = '';
  @Param value: ResourceStr = '';
  @Param chevron: boolean = false;
  @Param showDivider: boolean = true;
  @Event onTap: () => void = () => {
  };

  build() {
    Column() {
      Row({ space: Space.M }) {
        if (this.symbol !== undefined) {
          SymbolGlyph(this.symbol)
            .fontSize(20)
            .fontColor([this.symbolColor])
            .width(24)
        }
        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(FontSize.BODY)
            .fontColor($r('app.color.text_primary'))
          if (this.detail !== '') {
            Text(this.detail)
              .fontSize(FontSize.BODY_S)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (this.value !== '') {
          Text(this.value)
            .fontSize(FontSize.BODY_S)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.End)
            .constraintSize({ maxWidth: '55%' })
        }
        if (this.chevron) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([$r('app.color.text_tertiary')])
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 52 })
      .padding({ left: Space.L, right: Space.L, top: 10, bottom: 10 })

      if (this.showDivider) {
        Divider()
          .strokeWidth(0.5)
          .color($r('app.color.divider'))
          .margin({ left: this.symbol !== undefined ? Space.L + 24 + Space.M : Space.L })
      }
    }
    .onClick(() => this.onTap())
  }
}
