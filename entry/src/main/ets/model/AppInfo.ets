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
import { ObjectUtils } from '../utils/ObjectUtils';
import { ds_server } from '../data/DataSource';

class AppInfo {
  constructor(source?: Partial<AppInfo>) {
    ObjectUtils.assign(this, source);
  }

  /* 元数据 */
  id: number = 0
  name: string = ''
  desc: string = ''
  icon: string = ''
  vender: string = ''
  packageName: string = ''
  version: string = ''
  hapUrl: string = ''
  type: string = ''
  tags: string = ''
  openSourceAddress: string = ''
  releaseTime: string = ''
  /* 扩展数据 */
  // 应用状态
  status: AppStatus = AppStatus.NOT_INSTALLED
  // 操作按钮文本
  actionText: AppActionText = AppActionText.INSTALL

  getIcon() {
    return this.icon ? ds_server + this.icon : this.icon;
  }

  getHapUrl() {
    return this.hapUrl ? ds_server + this.hapUrl : this.hapUrl;
  }

  public ResourceToString(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource)
  }
}

enum AppType {
  APP = 'app',
  GAME = 'game'
}

enum AppStatus {
  NOT_INSTALLED = 0, // 未安装
  INSTALLED = 1, // 已安装
  UPDATABLE = 2, // 可更新
}

// todo: to be changed with resource type
enum AppActionText {
  OPEN = "Open",
  INSTALL = "Install",
  UPDATE = "Update"
}

// 定义映射接口，将标识符与实际资源字符串对应
interface AppActionClasses {
  open: string;
  install: string;
  update: string;
}

// 定义 ActionTextMap 接口，替代对象字面量类型
interface ActionTextMap {
  open: AppActionText;
  install: AppActionText;
  update: AppActionText;
}

// 使用 ActionTextMap 接口声明 actionTextMap 对象
const actionTextMap: ActionTextMap = {
  open: AppActionText.OPEN,
  install: AppActionText.INSTALL,
  update: AppActionText.UPDATE,
};

// 定义 classes 对象，使用标识符友好的键名
const classes: AppActionClasses = {
  open: getContext(this).resourceManager.getStringSync($r('app.string.open')),
  install: getContext(this).resourceManager.getStringSync($r('app.string.install')),
  update: getContext(this).resourceManager.getStringSync($r('app.string.update'))
};

export default function getEnumElement(variant:AppActionText):string {
  return Object(classes)[variant]
}

export {AppInfo, AppType, AppStatus, AppActionText, classes}