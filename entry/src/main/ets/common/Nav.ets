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

export class Routes {
  static readonly DETAIL: string = 'detail';
  static readonly SEARCH: string = 'search';
  static readonly LIST: string = 'list';
  static readonly SETTINGS: string = 'settings';
  static readonly ABOUT: string = 'about';
  static readonly WEB: string = 'web';
}

export class DetailParams {
  packageName: string = '';
}

/** Which apps a full-screen list shows. */
export enum ListKind {
  POPULAR = 0,
  RECENT = 1,
  GAMES = 2,
  FROM_SOURCE = 3,
  TAG = 4
}

export class ListParams {
  kind: ListKind = ListKind.POPULAR;
  // The tag, for ListKind.TAG.
  tag: string = '';
}

export class WebParams {
  title: string = '';
  url: string = '';
}

/** The app's single navigation stack, hosted by the Navigation in pages/Index. */
export const navStack: NavPathStack = new NavPathStack();

export class Nav {
  static openApp(packageName: string): void {
    const p: DetailParams = new DetailParams();
    p.packageName = packageName;
    navStack.pushPathByName(Routes.DETAIL, p);
  }

  static openList(kind: ListKind, tag: string): void {
    const p: ListParams = new ListParams();
    p.kind = kind;
    p.tag = tag;
    navStack.pushPathByName(Routes.LIST, p);
  }

  static openSearch(): void {
    navStack.pushPathByName(Routes.SEARCH, null);
  }

  static openSettings(): void {
    navStack.pushPathByName(Routes.SETTINGS, null);
  }

  static openAbout(): void {
    navStack.pushPathByName(Routes.ABOUT, null);
  }

  static openWeb(title: string, url: string): void {
    if (!url) {
      return;
    }
    const p: WebParams = new WebParams();
    p.title = title;
    p.url = url;
    navStack.pushPathByName(Routes.WEB, p);
  }

  static back(): void {
    navStack.pop();
  }
}
