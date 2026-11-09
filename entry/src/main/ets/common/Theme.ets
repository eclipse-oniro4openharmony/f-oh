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

/**
 * Layout tokens shared by every screen. Colours live in resources
 * (base/element/color.json, with dark/element/color.json for dark mode) so
 * they follow the system theme; reference them with $r('app.color.*').
 */
export class Space {
  static readonly XXS: number = 2;
  static readonly XS: number = 4;
  static readonly S: number = 8;
  static readonly M: number = 12;
  static readonly L: number = 16;
  static readonly XL: number = 24;
  static readonly XXL: number = 32;
  /** Horizontal page gutter. */
  static readonly GUTTER: number = 16;
}

export class Radius {
  static readonly S: number = 8;
  static readonly M: number = 12;
  static readonly L: number = 16;
  static readonly XL: number = 24;
  static readonly PILL: number = 999;
}

export class FontSize {
  static readonly CAPTION: number = 12;
  static readonly BODY_S: number = 13;
  static readonly BODY: number = 15;
  static readonly TITLE_S: number = 16;
  static readonly TITLE: number = 18;
  static readonly HEADLINE: number = 22;
  static readonly DISPLAY: number = 30;
}

export class Size {
  static readonly ICON_S: number = 48;
  static readonly ICON_M: number = 56;
  static readonly ICON_L: number = 64;
  static readonly ICON_XL: number = 96;
  static readonly TAB_BAR: number = 60;
  static readonly TOOLBAR: number = 56;
  static readonly ACTION_W: number = 76;
  static readonly ACTION_H: number = 32;
  static readonly TOUCH: number = 40;
}

/** Icon corner radius proportional to the icon size, like the launcher's squircle. */
export function iconRadius(size: number): number {
  return Math.round(size * 0.24);
}

export const STORE_HOST: string = 'store.iparo.app';
export const STORE_URL: string = 'https://' + STORE_HOST;
export const SOURCE_URL: string = 'https://github.com/eclipse-oniro4openharmony/f-oh';
export const ONIRO_URL: string = 'https://oniroproject.org/';
export const COMMUNITY_URL: string = 'https://github.com/eclipse-oniro4openharmony';
export const UPSTREAM_URL: string = 'https://github.com/westinyang';
