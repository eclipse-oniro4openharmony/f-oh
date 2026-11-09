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
import { AppState, installManager } from '../data/InstallManager';
import { AppIcon } from './AppIcon';
import { ActionButton, StatusTag } from './ActionButton';
import { FontSize, Size, Space } from '../common/Theme';
import { formatBytes } from '../common/Format';
import { Nav } from '../common/Nav';

/** Developer name with the verified badge. */
@ComponentV2
export struct DeveloperLine {
  @Param name: string = '';
  @Param verified: boolean = false;
  @Param fontSize: number = FontSize.BODY_S;
  @Param color: ResourceColor = $r('app.color.text_secondary');

  build() {
    // Flex, not Row: a long name shrinks and ellipsizes while the badge stays beside it.
    Flex({ alignItems: ItemAlign.Center }) {
      Text(this.name)
        .fontSize(this.fontSize)
        .fontColor(this.color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        // Ellipsize per character, not per word, so no gap opens before the badge.
        .wordBreak(WordBreak.BREAK_ALL)
        .flexShrink(1)
      if (this.verified) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(this.fontSize - 1)
          .fontColor([$r('app.color.brand')])
          .margin({ left: 4 })
          .flexShrink(0)
      }
    }
    .width('100%')
  }
}

/** One app in a list: icon, name, developer, a detail line, and its action button. */
@ComponentV2
export struct AppRow {
  @Param @Require app: AppInfo;
  // Library's updates section shows "1.0.0 → 1.1.0" instead of tag and size.
  @Param showVersionChange: boolean = false;
  @Param horizontalPadding: number = Space.GUTTER;

  build() {
    Row({ space: Space.M }) {
      AppIcon({ url: this.app.iconUrl, name: this.app.name, iconSize: Size.ICON_M })
      Column({ space: 3 }) {
        Text(this.app.name)
          .fontSize(FontSize.TITLE_S)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        DeveloperLine({ name: this.app.vendor, verified: this.app.verified })
        Row({ space: 6 }) {
          Text(this.detailLine(installManager.stateOf(this.app.packageName)))
            .fontSize(FontSize.CAPTION)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .flexShrink(1)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      ActionButton({ app: this.app, appState: installManager.stateOf(this.app.packageName) })
    }
    .width('100%')
    .padding({ left: this.horizontalPadding, right: this.horizontalPadding, top: 10, bottom: 10 })
    .onClick(() => Nav.openApp(this.app.packageName))
  }

  detailLine(s: AppState): string {
    const size: string = formatBytes(this.app.latest.fileSize);
    if (this.showVersionChange && s.installedVersionName !== '') {
      return s.installedVersionName + ' → ' + this.app.latest.versionName + '  ·  ' + size;
    }
    const tag: string = this.app.tags.length > 0 ? this.app.tags[0] + '  ·  ' : '';
    return tag + size;
  }
}

/** A tall card for horizontal carousels: big icon, name, tag. */
@ComponentV2
export struct AppCard {
  @Param @Require app: AppInfo;
  @Param iconSize: number = 76;

  build() {
    Column({ space: 6 }) {
      AppIcon({ url: this.app.iconUrl, name: this.app.name, iconSize: this.iconSize })
      Text(this.app.name)
        .fontSize(FontSize.BODY_S)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .lineHeight(17)
      Row() {
        StatusTag({ appState: installManager.stateOf(this.app.packageName) })
        Text(this.app.tags.length > 0 ? this.app.tags[0] : this.app.vendor)
          .fontSize(FontSize.CAPTION)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .visibility(this.hasStatus() ? Visibility.None : Visibility.Visible)
      }
      .width('100%')
    }
    .width(this.iconSize + 12)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => Nav.openApp(this.app.packageName))
  }

  hasStatus(): boolean {
    const s: AppState = installManager.stateOf(this.app.packageName);
    return s.installed || s.isBusy();
  }
}
