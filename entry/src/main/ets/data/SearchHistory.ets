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
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppContext } from '../common/AppContext';

const FILE: string = 'store_prefs';
const KEY: string = 'recent_searches';
const MAX_ENTRIES: number = 8;

function store(): preferences.Preferences | undefined {
  if (AppContext.ability === undefined) {
    return undefined;
  }
  try {
    return preferences.getPreferencesSync(AppContext.ability, { name: FILE });
  } catch (err) {
    hilog.warn(0x0000, 'SearchHistory', 'preferences: %{public}s', (err as BusinessError).message);
    return undefined;
  }
}

/** The last few searches, newest first, kept across launches. */
export class SearchHistory {
  static load(): string[] {
    const p: preferences.Preferences | undefined = store();
    if (p === undefined) {
      return [];
    }
    try {
      return JSON.parse(p.getSync(KEY, '[]') as string) as string[];
    } catch (err) {
      return [];
    }
  }

  static add(query: string): string[] {
    const q: string = query.trim();
    if (q === '') {
      return SearchHistory.load();
    }
    const list: string[] = SearchHistory.load().filter((s: string) => s.toLowerCase() !== q.toLowerCase());
    list.unshift(q);
    return SearchHistory.save(list.slice(0, MAX_ENTRIES));
  }

  static clear(): string[] {
    return SearchHistory.save([]);
  }

  private static save(list: string[]): string[] {
    const p: preferences.Preferences | undefined = store();
    if (p !== undefined) {
      p.putSync(KEY, JSON.stringify(list));
      p.flush().catch(() => {
      });
    }
    return list;
  }
}
