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
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'AppContext';
const TOAST_MS: number = 2000;

/**
 * Process-wide handles set once by EntryAbility, for code that runs outside
 * a component (downloads and installs keep going while pages come and go).
 */
export class AppContext {
  static ability: common.UIAbilityContext | undefined = undefined;
  static ui: UIContext | undefined = undefined;
  static filesDir: string = '';

  /** A string resource, formatted with %s/%d arguments. */
  static str(res: Resource, ...args: Array<string | number>): string {
    const ctx: common.UIAbilityContext | undefined = AppContext.ability;
    if (ctx === undefined) {
      return '';
    }
    try {
      return ctx.resourceManager.getStringSync(res.id, ...args);
    } catch (err) {
      hilog.warn(0x0000, TAG, 'string %{public}d: %{public}s', res.id, (err as BusinessError).message);
      return '';
    }
  }

  /** A plural resource for `count`, with %d filled by it. */
  static plural(res: Resource, count: number): string {
    const ctx: common.UIAbilityContext | undefined = AppContext.ability;
    if (ctx === undefined) {
      return count.toString();
    }
    try {
      return ctx.resourceManager.getIntPluralStringValueSync(res.id, count, count);
    } catch (err) {
      hilog.warn(0x0000, TAG, 'plural %{public}d: %{public}s', res.id, (err as BusinessError).message);
      return count.toString();
    }
  }

  static toast(message: string | Resource): void {
    const ui: UIContext | undefined = AppContext.ui;
    if (ui === undefined) {
      return;
    }
    try {
      ui.getPromptAction().showToast({ message: message, duration: TOAST_MS });
    } catch (err) {
      hilog.warn(0x0000, TAG, 'toast failed: %{public}s', (err as BusinessError).message);
    }
  }
}
