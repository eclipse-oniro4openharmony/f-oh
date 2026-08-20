/*
 * Copyright (C) 2023 westinyang https://gitee.com/ohos-dev
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
import { AppInfo, AppType } from '../model/AppInfo';
import { FORMAT_HAP } from '../utils/AppPackage';
import { http } from '@kit.NetworkKit';

// Oniro App Store backend (OpenAPI docs: https://fracta.dev/docs)
const ds_server: string = 'https://fracta.dev';
const api_base: string = ds_server + '/api/v1';
const api_apps: string = api_base + '/apps';
const api_healthz: string = api_base + '/healthz';

// Max page size allowed by GET /api/v1/apps
const PAGE_SIZE: number = 100;

interface ApiVersionSummary {
  versionName: string;
  versionCode: number;
  minApi: number | null;
  targetApi: number | null;
  fileSize: number;
  // 'hap' 或 'app'，旧版服务端不返回该字段
  format?: string;
}

interface ApiAppSummary {
  packageName: string;
  name: string;
  vendor: string;
  category: string;
  iconUrl: string | null;
  latestVersion: ApiVersionSummary;
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
  publisherName: string;
}

interface ApiAppDetailResponse {
  data: ApiAppDetail;
}

async function fetchJson(url: string): Promise<string> {
  let httpRequest = http.createHttp();
  try {
    let resp = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING
    });
    if (resp.responseCode != 200) {
      throw new Error('HTTP ' + resp.responseCode + ' for ' + url);
    }
    return resp.result as string;
  } finally {
    httpRequest.destroy();
  }
}

function toAppInfo(item: ApiAppSummary): AppInfo {
  let info = new AppInfo();
  info.name = item.name;
  info.packageName = item.packageName;
  info.vender = item.vendor;
  info.type = item.category;
  info.version = item.latestVersion.versionName;
  info.icon = item.iconUrl ?? '';
  info.hapUrl = api_apps + '/' + item.packageName + '/download';
  info.format = item.latestVersion.format ?? FORMAT_HAP;
  info.tags = item.tags.join(', ');
  return info;
}

class DataSource {
  public static allAppList: AppInfo[] = [];

  constructor() {
  }

  /**
   * 获取全部应用（自动翻页）
   */
  private static async fetchAllApps(): Promise<AppInfo[]> {
    let all: AppInfo[] = [];
    let page: number = 1;
    let total: number = 0;
    do {
      let text = await fetchJson(api_apps + '?page=' + page + '&pageSize=' + PAGE_SIZE);
      let resp = JSON.parse(text) as ApiAppListResponse;
      if (resp.data.length == 0) {
        // 服务端 total 与实际数据不一致时防止死循环
        break;
      }
      resp.data.forEach((item: ApiAppSummary) => {
        all.push(toAppInfo(item));
      });
      total = resp.meta.total;
      page++;
    } while (all.length < total);
    return all;
  }

  /**
   * 获取应用列表数据
   */
  static getAppList(appType: AppType, success: (data: AppInfo[], totalCount: number) => void,
    error?: (err: Error) => void) {
    DataSource.fetchAllApps().then((apps: AppInfo[]) => {
      DataSource.allAppList = apps;
      // 过滤类型
      let filterData: AppInfo[] = apps.filter((item: AppInfo) => {
        return item.type == appType;
      });
      success(filterData, apps.length);
    }).catch((err: Error) => {
      console.error('getAppList error: ' + err.message);
      if (error) {
        error(err);
      }
    });
  }

  /**
   * 获取应用详情（描述、源码地址、发布时间等）
   */
  static getAppDetail(packageName: string, success: (info: AppInfo) => void,
    error?: (err: Error) => void) {
    fetchJson(api_apps + '/' + packageName).then((text: string) => {
      let resp = JSON.parse(text) as ApiAppDetailResponse;
      let detail = resp.data;
      let info = toAppInfo(detail);
      info.desc = detail.description;
      info.openSourceAddress = detail.sourceUrl ?? '';
      info.releaseTime = detail.releaseTime ? detail.releaseTime.substring(0, 10) : '';
      success(info);
    }).catch((err: Error) => {
      console.error('getAppDetail error: ' + err.message);
      if (error) {
        error(err);
      }
    });
  }

  async fetchHttpCode(): Promise<number> {
    let httpRequest = http.createHttp();
    try {
      let resp = await httpRequest.request(api_healthz);
      return resp.responseCode;
    } catch (error) {
      console.error('Error fetching HTTP code:', error);
      return -1; // 返回一个错误码
    } finally {
      httpRequest.destroy();
    }
  }
}

export { DataSource }
