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

/** 1536 -> "1.5 KB", 108353277 -> "103 MB". */
export function formatBytes(bytes: number): string {
  if (!(bytes > 0)) {
    return '0 B';
  }
  const units: string[] = ['B', 'KB', 'MB', 'GB'];
  let value: number = bytes;
  let unit: number = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  const digits: number = value >= 100 || unit === 0 ? 0 : 1;
  return value.toFixed(digits) + ' ' + units[unit];
}

/** 950 -> "950", 1200 -> "1.2K", 999960 -> "1M", 3400000 -> "3.4M". */
export function formatCount(n: number): string {
  if (n < 1000) {
    return n.toString();
  }
  // Round first, then pick the unit: 999960 is "1M", not "1000K".
  const thousands: number = Math.round(n / 100) / 10;
  if (thousands < 1000) {
    return trimZero(thousands.toFixed(1)) + 'K';
  }
  return trimZero((Math.round(n / 100000) / 10).toFixed(1)) + 'M';
}

function trimZero(s: string): string {
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/** ISO timestamp -> "2026-11-08"; '' stays ''. */
export function formatDate(iso: string): string {
  return iso ? iso.substring(0, 10) : '';
}

/** Lower-case and strip accents and punctuation so search matches loosely: "Café" -> "cafe". */
export function normalize(s: string): string {
  return s.normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[\s_\-.:]+/g, ' ')
    .trim();
}

/** Two letters for an app without an icon: "Oniro Browser" -> "OB". */
export function initials(name: string): string {
  const words: string[] = name.trim().split(/\s+/).filter((w: string) => w.length > 0);
  if (words.length === 0) {
    return '?';
  }
  if (words.length === 1) {
    return words[0].substring(0, 2).toUpperCase();
  }
  return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
}
