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
import { iconRadius, Size } from '../common/Theme';
import { initials } from '../common/Format';

/** An app icon in the launcher's rounded shape; shows the app's initials until (or unless) it loads. */
@ComponentV2
export struct AppIcon {
  @Param url: string = '';
  @Param name: string = '';
  @Param iconSize: number = Size.ICON_M;
  @Local loaded: boolean = false;
  @Local failed: boolean = false;

  @Monitor('url')
  onUrlChange(): void {
    this.loaded = false;
    this.failed = false;
  }

  build() {
    Stack() {
      if (!this.loaded) {
        Text(initials(this.name))
          .fontSize(Math.round(this.iconSize * 0.34))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.on_brand_soft'))
      }
      if (this.url && !this.failed) {
        Image(this.url)
          .width(this.iconSize)
          .height(this.iconSize)
          .objectFit(ImageFit.Cover)
          .draggable(false)
          .syncLoad(false)
          .onComplete(() => {
            this.loaded = true;
          })
          .onError(() => {
            this.failed = true;
          })
      }
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .backgroundColor(this.loaded ? $r('app.color.surface') : $r('app.color.brand_soft'))
    .borderRadius(iconRadius(this.iconSize))
    .border({ width: 0.5, color: $r('app.color.divider'), radius: iconRadius(this.iconSize) })
    .clip(true)
    .flexShrink(0)
  }
}
