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
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppInfo } from '../model/AppInfo';
import { fetchAppDetail, fetchCatalog } from './StoreApi';
import { installManager } from './InstallManager';
import { normalize } from '../common/Format';

const TAG: string = 'Catalog';

export enum LoadState {
  IDLE = 0,
  LOADING = 1,
  READY = 2,
  ERROR = 3
}

export enum SortMode {
  POPULAR = 0,
  RECENT = 1,
  NAME = 2
}

export class TagCount {
  name: string = '';
  count: number = 0;
}

function sortApps(apps: AppInfo[], mode: SortMode): AppInfo[] {
  const out: AppInfo[] = apps.slice();
  if (mode === SortMode.POPULAR) {
    out.sort((a: AppInfo, b: AppInfo) => b.totalDownloads - a.totalDownloads || a.recentRank - b.recentRank);
  } else if (mode === SortMode.RECENT) {
    out.sort((a: AppInfo, b: AppInfo) => a.recentRank - b.recentRank);
  } else {
    out.sort((a: AppInfo, b: AppInfo) => a.name.localeCompare(b.name));
  }
  return out;
}

/**
 * The whole store catalogue, fetched once and shared by every screen. It is
 * small (tens of apps), so filtering, sorting and search run on the device
 * and stay instant and consistent across tabs.
 */
@ObservedV2
export class Catalog {
  @Trace apps: AppInfo[] = [];
  @Trace state: LoadState = LoadState.IDLE;
  // A refresh is in flight while apps are already shown.
  @Trace refreshing: boolean = false;
  private details: Map<string, AppInfo> = new Map<string, AppInfo>();

  /**
   * Fetch the catalogue; `force` refetches even when it is already loaded.
   * Resolves false when the fetch failed (never rejects).
   */
  async load(force: boolean): Promise<boolean> {
    if (this.state === LoadState.LOADING || this.refreshing) {
      return true;
    }
    if (!force && this.state === LoadState.READY) {
      return true;
    }
    const hadApps: boolean = this.apps.length > 0;
    if (hadApps) {
      this.refreshing = true;
    } else {
      this.state = LoadState.LOADING;
    }
    try {
      const apps: AppInfo[] = await fetchCatalog();
      this.details.clear();
      this.apps = apps;
      this.state = LoadState.READY;
      this.refreshing = false;
      await installManager.sync(apps);
      return true;
    } catch (err) {
      hilog.error(0x0000, TAG, 'catalog load failed: %{public}s', (err as Error).message);
      // Keep showing what we have; only an empty store is an error screen.
      this.state = hadApps ? LoadState.READY : LoadState.ERROR;
      this.refreshing = false;
      return false;
    }
  }

  find(packageName: string): AppInfo | undefined {
    return this.apps.find((a: AppInfo) => a.packageName === packageName);
  }

  inCategory(category: string, sort: SortMode, tag: string): AppInfo[] {
    const apps: AppInfo[] = this.apps.filter((a: AppInfo) =>
    a.category === category && (tag === '' || a.tags.indexOf(tag) >= 0));
    return sortApps(apps, sort);
  }

  popular(limit: number): AppInfo[] {
    return sortApps(this.apps, SortMode.POPULAR).slice(0, limit);
  }

  recent(limit: number): AppInfo[] {
    return sortApps(this.apps, SortMode.RECENT).slice(0, limit);
  }

  games(limit: number): AppInfo[] {
    return this.inCategory('game', SortMode.POPULAR, '').slice(0, limit);
  }

  builtFromSource(limit: number): AppInfo[] {
    return sortApps(this.apps.filter((a: AppInfo) => a.isBuiltFromSource()), SortMode.POPULAR).slice(0, limit);
  }

  withTag(tag: string, sort: SortMode): AppInfo[] {
    return sortApps(this.apps.filter((a: AppInfo) => a.tags.indexOf(tag) >= 0), sort);
  }

  /** Tags used by at least `minApps` apps (of `category`, or all when ''), most used first. */
  tags(category: string, minApps: number): TagCount[] {
    const counts: Map<string, number> = new Map<string, number>();
    this.apps.forEach((a: AppInfo) => {
      if (category !== '' && a.category !== category) {
        return;
      }
      a.tags.forEach((t: string) => {
        counts.set(t, (counts.get(t) ?? 0) + 1);
      });
    });
    const out: TagCount[] = [];
    counts.forEach((count: number, name: string) => {
      if (count >= minApps) {
        const t: TagCount = new TagCount();
        t.name = name;
        t.count = count;
        out.push(t);
      }
    });
    out.sort((a: TagCount, b: TagCount) => b.count - a.count || a.name.localeCompare(b.name));
    return out;
  }

  /**
   * Apps matching every word of `query` in their name, developer, tags or
   * package name; name matches rank first, then popularity.
   */
  search(query: string): AppInfo[] {
    const words: string[] = normalize(query).split(' ').filter((w: string) => w.length > 0);
    if (words.length === 0) {
      return [];
    }
    const scored: AppInfo[] = [];
    const scores: Map<string, number> = new Map<string, number>();
    this.apps.forEach((a: AppInfo) => {
      const name: string = normalize(a.name);
      const rest: string = normalize(a.vendor + ' ' + a.tags.join(' ') + ' ' + a.packageName);
      let score: number = 0;
      for (const w of words) {
        if (name.startsWith(w) || name.indexOf(' ' + w) >= 0) {
          score += 3;
        } else if (name.indexOf(w) >= 0) {
          score += 2;
        } else if (rest.indexOf(w) >= 0) {
          score += 1;
        } else {
          return;
        }
      }
      scores.set(a.packageName, score);
      scored.push(a);
    });
    scored.sort((a: AppInfo, b: AppInfo) =>
    (scores.get(b.packageName) ?? 0) - (scores.get(a.packageName) ?? 0) || b.totalDownloads - a.totalDownloads);
    return scored;
  }

  /** Cached full listing of an app, fetched on first use. */
  async detail(packageName: string): Promise<AppInfo> {
    const cached: AppInfo | undefined = this.details.get(packageName);
    if (cached !== undefined) {
      return cached;
    }
    const rank: number = this.find(packageName)?.recentRank ?? 0;
    const info: AppInfo = await fetchAppDetail(packageName, rank);
    this.details.set(packageName, info);
    return info;
  }
}

export const catalog: Catalog = new Catalog();
