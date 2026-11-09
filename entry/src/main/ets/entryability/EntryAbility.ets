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
import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { applySystemBars } from '../utils/WindowStageUtil';
import { AppContext } from '../common/AppContext';

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | undefined = undefined;

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
    AppContext.ability = this.context;
    AppContext.filesDir = this.context.filesDir;
    this.applyTheme(this.context.config.colorMode);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'EntryAbility', 'Failed to load the content: %{public}s', JSON.stringify(err));
        return;
      }
      try {
        AppContext.ui = windowStage.getMainWindowSync().getUIContext();
      } catch (e) {
        hilog.error(0x0000, 'EntryAbility', 'no UIContext: %{public}s', JSON.stringify(e));
      }
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    // Light/dark switch: resource colours follow by themselves, the bars do not.
    this.applyTheme(newConfig.colorMode);
  }

  private applyTheme(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    if (this.windowStage !== undefined) {
      applySystemBars(this.windowStage, this.context, colorMode, $r('app.color.bg').id, $r('app.color.tab_bar').id);
    }
  }
}
