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

export enum AppCategory {
  APP = 'app',
  GAME = 'game'
}

/** Package formats served by the store: a single module, or a bundle of them. */
export const FORMAT_HAP: string = 'hap';
export const FORMAT_APP: string = 'app';

/** buildKind of a version the store's CI built from a tagged commit. */
export const BUILD_FROM_SOURCE: string = 'ci_source';

/** One published version of an app. */
export class VersionInfo {
  versionName: string = '';
  versionCode: number = 0;
  minApi: number = 0;
  targetApi: number = 0;
  fileSize: number = 0;
  // FORMAT_HAP or FORMAT_APP
  format: string = FORMAT_HAP;
  // SHA-256 (lowercase hex) of the exact bytes served; '' when the server
  // reports none (older backends), in which case it is not checked.
  sha256: string = '';
  // Version-pinned download URL (absolute).
  downloadUrl: string = '';
  // 'uploaded' or BUILD_FROM_SOURCE.
  buildKind: string = '';
  // Detail endpoint only.
  releaseTime: string = '';
  downloadCount: number = 0;
  commitSha: string = '';
  commitUrl: string = '';
  repository: string = '';
}

/**
 * An app as listed by the store. The list endpoint fills the summary; the
 * detail endpoint adds description, source, versions (hasDetail = true).
 * Instances are treated as immutable: a refresh replaces them.
 */
export class AppInfo {
  packageName: string = '';
  name: string = '';
  vendor: string = '';
  developerUrl: string = '';
  verified: boolean = false;
  category: string = AppCategory.APP;
  iconUrl: string = '';
  tags: string[] = [];
  totalDownloads: number = 0;
  latest: VersionInfo = new VersionInfo();
  // Position in the store's "most recently updated first" order.
  recentRank: number = 0;

  hasDetail: boolean = false;
  description: string = '';
  sourceUrl: string = '';
  releaseTime: string = '';
  versions: VersionInfo[] = [];

  isGame(): boolean {
    return this.category === AppCategory.GAME;
  }

  isBuiltFromSource(): boolean {
    return this.latest.buildKind === BUILD_FROM_SOURCE;
  }
}
