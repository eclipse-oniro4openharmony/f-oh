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
import fs from '@ohos.file.fs';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'Cache';

/**
 * Downloaded packages (and bundles unpacked for install) live directly in the
 * app's files directory. These helpers measure and empty it, keeping the
 * directory itself, which downloads are written into.
 */
export function cacheSize(dir: string): number {
  if (!dir) {
    return 0;
  }
  let total: number = 0;
  try {
    const files: string[] = fs.listFileSync(dir, { recursion: true });
    files.forEach((rel: string) => {
      try {
        // Recursive listings are relative to `dir` and start with '/'.
        total += fs.statSync(dir + (rel.startsWith('/') ? '' : '/') + rel).size;
      } catch (err) {
        // A file removed while listing.
      }
    });
  } catch (err) {
    hilog.warn(0x0000, TAG, 'measuring %{public}s failed: %{public}s', dir, (err as BusinessError).message);
  }
  return total;
}

/** Delete everything inside `dir`. Resolves false if anything could not be deleted. */
export async function clearCache(dir: string): Promise<boolean> {
  if (!dir) {
    return false;
  }
  let ok: boolean = true;
  let names: string[] = [];
  try {
    names = await fs.listFile(dir);
  } catch (err) {
    hilog.error(0x0000, TAG, 'listing %{public}s failed: %{public}s', dir, (err as BusinessError).message);
    return false;
  }
  for (const name of names) {
    const path: string = dir + '/' + name;
    try {
      const stat: fs.Stat = await fs.stat(path);
      if (stat.isDirectory()) {
        await fs.rmdir(path); // recursive
      } else {
        await fs.unlink(path);
      }
    } catch (err) {
      ok = false;
      hilog.error(0x0000, TAG, 'deleting %{public}s failed: %{public}s', path, (err as BusinessError).message);
    }
  }
  return ok;
}
