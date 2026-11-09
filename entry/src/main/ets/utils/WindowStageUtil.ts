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
import { window } from '@kit.ArkUI';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'WindowStageUtil';

function colorHex(ctx: common.UIAbilityContext, id: number, fallback: string): string {
  try {
    const argb: number = ctx.resourceManager.getColorSync(id);
    return '#' + (argb >>> 0).toString(16).padStart(8, '0');
  } catch (err) {
    return fallback;
  }
}

/**
 * Colour the status and navigation bars to match the app's background in the
 * current light/dark theme. Called at startup and whenever the colour mode
 * changes.
 */
export function applySystemBars(windowStage: window.WindowStage, ctx: common.UIAbilityContext,
  colorMode: ConfigurationConstant.ColorMode | undefined, statusBarColorId: number, navigationBarColorId: number): void {
  const dark: boolean = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  const content: string = dark ? '#FFFFFF' : '#000000';
  windowStage.getMainWindow().then((win: window.Window) => {
    win.setWindowLayoutFullScreen(false).catch((err: Error) => {
      hilog.warn(0x0000, TAG, 'layout: %{public}s', err.message);
    });
    // Shows below the tab bar where gesture navigation ignores navigationBarColor.
    win.setWindowBackgroundColor(colorHex(ctx, navigationBarColorId, dark ? '#FF15111D' : '#FFFFFFFF'));
    const props: window.SystemBarProperties = {
      statusBarColor: colorHex(ctx, statusBarColorId, dark ? '#FF0E0B16' : '#FFF6F4FA'),
      statusBarContentColor: content,
      navigationBarColor: colorHex(ctx, navigationBarColorId, dark ? '#FF15111D' : '#FFFFFFFF'),
      navigationBarContentColor: content
    };
    win.setWindowSystemBarProperties(props).catch((err: Error) => {
      hilog.warn(0x0000, TAG, 'system bars: %{public}s', err.message);
    });
  }).catch((err: Error) => {
    hilog.error(0x0000, TAG, 'no main window: %{public}s', err.message);
  });
}
