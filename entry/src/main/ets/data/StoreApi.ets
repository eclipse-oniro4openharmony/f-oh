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
import { http } from '@kit.NetworkKit';
import { AppInfo, FORMAT_HAP, VersionInfo } from '../model/AppInfo';
import { STORE_URL } from '../common/Theme';

// Oniro App Store backend (OpenAPI docs: https://store.iparo.app/docs)
const API_APPS: string = STORE_URL + '/api/v1/apps';
// Max page size allowed by GET /api/v1/apps
const PAGE_SIZE: number = 100;
const TIMEOUT_MS: number = 15000;

interface ApiDeveloper {
  name: string;
  url: string | null;
  verified: boolean;
}

interface ApiProvenance {
  repository?: string;
  commitSha?: string;
  commitUrl?: string;
}

interface ApiVersion {
  versionName: string;
  versionCode: number;
  minApi: number | null;
  targetApi: number | null;
  fileSize: number;
  // Fields below are absent from older servers.
  format?: string;
  sha256?: string;
  downloadUrl?: string;
  buildKind?: string;
  // Detail endpoint only.
  releaseTime?: string;
  downloadCount?: number;
  provenance?: ApiProvenance | null;
}

interface ApiAppSummary {
  packageName: string;
  name: string;
  vendor: string;
  developer?: ApiDeveloper;
  category: string;
  iconUrl: string | null;
  iconVersion?: string;
  latestVersion: ApiVersion;
  tags: string[];
  totalDownloads: number;
}

interface ApiListMeta {
  page: number;
  pageSize: number;
  total: number;
}

interface ApiAppListResponse {
  data: ApiAppSummary[];
  meta: ApiListMeta;
}

interface ApiAppDetail extends ApiAppSummary {
  description: string;
  sourceUrl: string | null;
  releaseTime: string;
  versions?: ApiVersion[];
}

interface ApiAppDetailResponse {
  data: ApiAppDetail;
}

async function fetchJson(url: string): Promise<string> {
  const httpRequest: http.HttpRequest = http.createHttp();
  try {
    const resp: http.HttpResponse = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: TIMEOUT_MS,
      readTimeout: TIMEOUT_MS
    });
    if (resp.responseCode !== 200) {
      throw new Error('HTTP ' + resp.responseCode + ' for ' + url);
    }
    return resp.result as string;
  } finally {
    httpRequest.destroy();
  }
}

function toVersion(v: ApiVersion, packageName: string): VersionInfo {
  const out: VersionInfo = new VersionInfo();
  out.versionName = v.versionName;
  out.versionCode = v.versionCode;
  out.minApi = v.minApi ?? 0;
  out.targetApi = v.targetApi ?? 0;
  out.fileSize = v.fileSize;
  out.format = v.format ?? FORMAT_HAP;
  out.sha256 = (v.sha256 ?? '').toLowerCase();
  // Prefer the version-pinned URL: '/download' resolves to whatever is latest
  // when the request arrives, which may no longer match the hash listed here.
  out.downloadUrl = v.downloadUrl ?? (API_APPS + '/' + packageName + '/download');
  out.buildKind = v.buildKind ?? '';
  out.releaseTime = v.releaseTime ?? '';
  out.downloadCount = v.downloadCount ?? 0;
  const p: ApiProvenance | null | undefined = v.provenance;
  if (p) {
    out.commitSha = p.commitSha ?? '';
    out.commitUrl = p.commitUrl ?? '';
    out.repository = p.repository ?? '';
  }
  return out;
}

function toAppInfo(item: ApiAppSummary, rank: number): AppInfo {
  const info: AppInfo = new AppInfo();
  info.packageName = item.packageName;
  info.name = item.name;
  info.vendor = item.developer?.name ?? item.vendor;
  info.developerUrl = item.developer?.url ?? '';
  info.verified = item.developer?.verified ?? false;
  info.category = item.category;
  // The icon URL is stable across icon changes; the version busts caches.
  const icon: string = item.iconUrl ?? '';
  info.iconUrl = icon && item.iconVersion ? icon + '?v=' + item.iconVersion : icon;
  info.tags = item.tags;
  info.totalDownloads = item.totalDownloads;
  info.latest = toVersion(item.latestVersion, item.packageName);
  info.recentRank = rank;
  return info;
}

/** Every app in the catalogue, most recently updated first (pages through the list). */
export async function fetchCatalog(): Promise<AppInfo[]> {
  const all: AppInfo[] = [];
  let page: number = 1;
  let total: number = 0;
  do {
    const text: string = await fetchJson(API_APPS + '?sort=recent&page=' + page + '&pageSize=' + PAGE_SIZE);
    const resp: ApiAppListResponse = JSON.parse(text) as ApiAppListResponse;
    if (resp.data.length === 0) {
      // Guards against a total that disagrees with the data.
      break;
    }
    resp.data.forEach((item: ApiAppSummary) => {
      all.push(toAppInfo(item, all.length));
    });
    total = resp.meta.total;
    page++;
  } while (all.length < total);
  return all;
}

/** Full listing of one app: description, source, every version. */
export async function fetchAppDetail(packageName: string, rank: number): Promise<AppInfo> {
  const text: string = await fetchJson(API_APPS + '/' + encodeURIComponent(packageName));
  const detail: ApiAppDetail = (JSON.parse(text) as ApiAppDetailResponse).data;
  const info: AppInfo = toAppInfo(detail, rank);
  info.hasDetail = true;
  info.description = detail.description ?? '';
  info.sourceUrl = detail.sourceUrl ?? '';
  info.releaseTime = detail.releaseTime ?? '';
  info.versions = (detail.versions ?? []).map((v: ApiVersion) => toVersion(v, detail.packageName));
  // The latest version carries provenance only in the versions list.
  const latest: VersionInfo | undefined =
    info.versions.find((v: VersionInfo) => v.versionCode === info.latest.versionCode);
  if (latest !== undefined) {
    info.latest = latest;
  }
  return info;
}
