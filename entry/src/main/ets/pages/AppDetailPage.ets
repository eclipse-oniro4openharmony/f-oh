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
import { MeasureOptions } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { AppInfo, FORMAT_APP, VersionInfo } from '../model/AppInfo';
import { catalog } from '../data/Catalog';
import { AppState, installManager, Phase } from '../data/InstallManager';
import { AppIcon } from '../components/AppIcon';
import { ActionButton } from '../components/ActionButton';
import { DeveloperLine } from '../components/AppRow';
import { CardRow, Chip, PageToolbar } from '../components/Common';
import { DetailParams, ListKind, Nav } from '../common/Nav';
import { FontSize, Radius, Size, Space } from '../common/Theme';
import { formatBytes, formatCount, formatDate } from '../common/Format';
import { AppContext } from '../common/AppContext';

const COLLAPSED_LINES: number = 5;
const DESCRIPTION_LINE_HEIGHT: number = 22;
// Descriptions shorter than this fit in the collapsed view.
const LONG_DESCRIPTION: number = 220;
const TITLE_AFTER_SCROLL: number = 96;
const MAX_VERSIONS: number = 10;

@Styles
function card() {
  .backgroundColor($r('app.color.surface'))
  .borderRadius(Radius.L)
}

/** One figure of the stats strip. A component, so it updates when the detail arrives. */
@ComponentV2
struct StatCell {
  @Param value: string = '';
  @Param label: ResourceStr = '';

  build() {
    Column({ space: 2 }) {
      Text(this.value)
        .fontSize(FontSize.TITLE_S)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.label)
        .fontSize(FontSize.CAPTION - 1)
        .fontColor($r('app.color.text_tertiary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ left: Space.XS, right: Space.XS })
  }
}

/** Everything about one app, with its install / update / open / uninstall actions. */
@ComponentV2
export struct AppDetailPage {
  @Param @Require params: DetailParams;
  @Local app: AppInfo = new AppInfo();
  @Local loadingDetail: boolean = true;
  @Local detailFailed: boolean = false;
  @Local expanded: boolean = false;
  @Local descriptionWidth: number = 0;
  @Local showTitle: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const summary: AppInfo | undefined = catalog.find(this.params.packageName);
    if (summary !== undefined) {
      this.app = summary;
    } else {
      const placeholder: AppInfo = new AppInfo();
      placeholder.packageName = this.params.packageName;
      this.app = placeholder;
    }
    this.loadDetail();
  }

  loadDetail(): void {
    this.loadingDetail = true;
    this.detailFailed = false;
    catalog.detail(this.params.packageName).then((info: AppInfo) => {
      this.app = info;
      this.loadingDetail = false;
      if (installManager.stateOf(info.packageName).phase === Phase.UNKNOWN) {
        installManager.sync([info]);
      }
    }).catch((err: Error) => {
      this.loadingDetail = false;
      this.detailFailed = true;
    });
  }

  appState(): AppState {
    return installManager.stateOf(this.app.packageName);
  }

  build() {
    NavDestination() {
      Column() {
        PageToolbar({ title: this.showTitle ? this.app.name : '' })
        Scroll(this.scroller) {
          Column() {
            this.Header()
            Column() {
              ActionButton({ app: this.app, appState: this.appState(), wide: true })
            }
            .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.XL })

            this.Stats()
            this.About()
            if (this.app.tags.length > 0) {
              this.Tags()
            }
            if (this.app.hasDetail) {
              this.Trust()
              this.Info()
              if (this.app.versions.length > 0) {
                this.Versions()
              }
            }
          }
          .width('100%')
          .padding({ bottom: Space.XXL + Space.L })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onDidScroll(() => {
          this.showTitle = this.scroller.currentOffset().yOffset > TITLE_AFTER_SCROLL;
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
  }

  /** The primary tag ("Utility"), as list rows show it; the section name when untagged. */
  kindLabel(): ResourceStr {
    if (this.app.tags.length > 0) {
      return this.app.tags[0];
    }
    return this.app.isGame() ? $r('app.string.tab_games') : $r('app.string.tab_apps');
  }

  @Builder
  Header() {
    Row({ space: Space.L }) {
      AppIcon({ url: this.app.iconUrl, name: this.app.name, iconSize: Size.ICON_XL })
      Column({ space: Space.XS }) {
        Text(this.app.name)
          .fontSize(FontSize.HEADLINE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        DeveloperLine({
          name: this.app.vendor,
          verified: this.app.verified,
          fontSize: FontSize.BODY,
          color: $r('app.color.brand')
        })
          .onClick(() => Nav.openWeb(this.app.vendor, this.app.developerUrl))
        Text(this.kindLabel())
          .fontSize(FontSize.CAPTION)
          .fontColor($r('app.color.text_tertiary'))
          .onClick(() => {
            if (this.app.tags.length > 0) {
              Nav.openList(ListKind.TAG, this.app.tags[0]);
            }
          })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.S })
  }

  @Builder
  Stats() {
    Row() {
      StatCell({ value: formatCount(this.app.totalDownloads), label: $r('app.string.detail_downloads') })
      this.StatDivider()
      StatCell({ value: formatBytes(this.app.latest.fileSize), label: $r('app.string.detail_size') })
      this.StatDivider()
      StatCell({ value: this.app.latest.versionName || '—', label: $r('app.string.detail_version') })
      this.StatDivider()
      StatCell({
        value: this.app.latest.minApi > 0 ? this.app.latest.minApi.toString() + '+' : '—',
        label: $r('app.string.detail_api')
      })
    }
    .card()
    .width('auto')
    .padding({ top: Space.M, bottom: Space.M })
    .margin({ left: Space.GUTTER, right: Space.GUTTER, top: Space.XL })
  }

  @Builder
  StatDivider() {
    Divider()
      .vertical(true)
      .height(28)
      .strokeWidth(0.5)
      .color($r('app.color.divider'))
  }

  @Builder
  SectionTitle(title: Resource) {
    Text(title)
      .fontSize(FontSize.TITLE)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.text_primary'))
      .width('100%')
      .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.XL, bottom: Space.S })
  }

  @Builder
  About() {
    this.SectionTitle($r('app.string.detail_about'))
    Column({ space: Space.S }) {
      if (this.loadingDetail && !this.app.hasDetail) {
        Column().width('100%').height(13).borderRadius(6).backgroundColor($r('app.color.skeleton'))
        Column().width('92%').height(13).borderRadius(6).backgroundColor($r('app.color.skeleton'))
        Column().width('60%').height(13).borderRadius(6).backgroundColor($r('app.color.skeleton'))
      } else if (this.detailFailed && !this.app.hasDetail) {
        Row({ space: Space.S }) {
          Text($r('app.string.network_error'))
            .fontSize(FontSize.BODY)
            .fontColor($r('app.color.text_secondary'))
          Text($r('app.string.action_retry'))
            .fontSize(FontSize.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.brand'))
            .onClick(() => this.loadDetail())
        }
      } else {
        Text(this.app.description || AppContext.str($r('app.string.detail_no_description')))
          .fontSize(FontSize.BODY)
          .lineHeight(DESCRIPTION_LINE_HEIGHT)
          .fontColor(this.app.description ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
          .maxLines(this.expanded ? 1000 : COLLAPSED_LINES)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .copyOption(CopyOptions.LocalDevice)
          .onAreaChange((oldArea: Area, newArea: Area) => {
            const width: number = Number(newArea.width);
            if (width !== this.descriptionWidth) {
              this.descriptionWidth = width;
            }
          })
        if (this.isLongDescription()) {
          Text(this.expanded ? $r('app.string.detail_less') : $r('app.string.detail_more'))
            .fontSize(FontSize.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.brand'))
            .padding({ top: Space.XS, bottom: Space.XS })
            .onClick(() => {
              this.getUIContext().animateTo({ duration: 200 }, () => {
                this.expanded = !this.expanded;
              });
            })
        }
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: Space.GUTTER, right: Space.GUTTER })
  }

  /** Does the description need more than the collapsed lines, at this width and font size? */
  isLongDescription(): boolean {
    const d: string = this.app.description;
    if (d === '') {
      return false;
    }
    const guess: boolean = d.length > LONG_DESCRIPTION || d.split('\n').length > COLLAPSED_LINES;
    if (this.descriptionWidth <= 0) {
      return guess; // not laid out yet
    }
    try {
      const options: MeasureOptions = {
        textContent: d,
        constraintWidth: this.descriptionWidth,
        fontSize: FontSize.BODY,
        lineHeight: DESCRIPTION_LINE_HEIGHT
      };
      const full: SizeOptions = this.getUIContext().getMeasureUtils().measureTextSize(options);
      options.maxLines = COLLAPSED_LINES;
      const collapsed: SizeOptions = this.getUIContext().getMeasureUtils().measureTextSize(options);
      return Number(full.height) > Number(collapsed.height) + 1;
    } catch (err) {
      return guess;
    }
  }

  @Builder
  Tags() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.app.tags, (tag: string) => {
        Chip({ label: tag, onTap: () => Nav.openList(ListKind.TAG, tag) })
          .margin({ right: Space.S, bottom: Space.S })
      }, (tag: string) => tag)
    }
    .padding({ left: Space.GUTTER, right: Space.GUTTER, top: Space.L })
  }

  @Builder
  Trust() {
    if (this.app.verified || this.app.isBuiltFromSource() || this.app.latest.sha256 !== '') {
      this.SectionTitle($r('app.string.detail_trust'))
      Column() {
        if (this.app.verified) {
          CardRow({
            symbol: $r('sys.symbol.checkmark_circle_fill'),
            title: $r('app.string.trust_verified_dev'),
            detail: $r('app.string.trust_verified_dev_desc'),
            chevron: this.app.developerUrl !== '',
            onTap: () => Nav.openWeb(this.app.vendor, this.app.developerUrl)
          })
        }
        if (this.app.isBuiltFromSource()) {
          CardRow({
            symbol: $r('sys.symbol.hammer_fill'),
            symbolColor: $r('app.color.cyan'),
            title: $r('app.string.trust_built_from_source'),
            detail: this.app.latest.commitSha ?
            AppContext.str($r('app.string.trust_built_from_source_desc'), this.app.latest.commitSha.substring(0, 7)) :
              '',
            chevron: this.app.latest.commitUrl !== '',
            onTap: () => Nav.openWeb(this.app.name, this.app.latest.commitUrl)
          })
        }
        if (this.app.latest.sha256 !== '') {
          CardRow({
            symbol: $r('sys.symbol.checkmark_shield_fill'),
            symbolColor: $r('app.color.success'),
            title: $r('app.string.trust_checksum'),
            detail: $r('app.string.trust_checksum_desc'),
            showDivider: false,
            onTap: () => this.copy(this.app.latest.sha256)
          })
        }
      }
      .card()
      .margin({ left: Space.GUTTER, right: Space.GUTTER })
    }
  }

  @Builder
  Info() {
    this.SectionTitle($r('app.string.detail_info'))
    Column() {
      CardRow({
        title: $r('app.string.detail_developer'),
        value: this.app.vendor,
        chevron: this.app.developerUrl !== '',
        onTap: () => Nav.openWeb(this.app.vendor, this.app.developerUrl)
      })
      CardRow({
        title: $r('app.string.detail_package'),
        value: this.app.packageName,
        onTap: () => this.copy(this.app.packageName)
      })
      CardRow({
        title: $r('app.string.detail_version'),
        value: this.app.latest.versionName + ' (' + this.app.latest.versionCode + ')'
      })
      if (this.appState().installed) {
        CardRow({
          title: $r('app.string.detail_installed_version'),
          value: this.appState().installedVersionName
        })
      }
      if (this.releaseDate() !== '') {
        CardRow({ title: $r('app.string.detail_released'), value: this.releaseDate() })
      }
      CardRow({ title: $r('app.string.detail_size'), value: formatBytes(this.app.latest.fileSize) })
      CardRow({
        title: $r('app.string.detail_format'),
        value: this.app.latest.format === FORMAT_APP ? '.app' : '.hap'
      })
      if (this.app.latest.minApi > 0) {
        CardRow({ title: $r('app.string.detail_api'), value: this.apiRange() })
      }
      CardRow({
        title: $r('app.string.detail_source'),
        value: this.app.sourceUrl ? this.app.sourceUrl.replace(/^https?:\/\//, '') : '—',
        chevron: this.app.sourceUrl !== '',
        showDivider: false,
        onTap: () => Nav.openWeb(this.app.name, this.app.sourceUrl)
      })
    }
    .card()
    .margin({ left: Space.GUTTER, right: Space.GUTTER })
  }

  releaseDate(): string {
    return formatDate(this.app.latest.releaseTime || this.app.releaseTime);
  }

  apiRange(): string {
    const v: VersionInfo = this.app.latest;
    if (v.targetApi > 0 && v.targetApi !== v.minApi) {
      return v.minApi + ' – ' + v.targetApi;
    }
    return v.minApi.toString();
  }

  @Builder
  Versions() {
    this.SectionTitle($r('app.string.detail_versions'))
    Column() {
      ForEach(this.app.versions.slice(0, MAX_VERSIONS), (v: VersionInfo, i: number) => {
        Column() {
          Row({ space: Space.M }) {
            Column({ space: 2 }) {
              Row({ space: Space.S }) {
                Text(v.versionName)
                  .fontSize(FontSize.BODY)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                if (i === 0) {
                  Text($r('app.string.detail_latest'))
                    .fontSize(10)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.on_brand_soft'))
                    .backgroundColor($r('app.color.brand_soft'))
                    .borderRadius(Radius.PILL)
                    .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                }
              }
              Text(formatDate(v.releaseTime) + '  ·  ' + formatBytes(v.fileSize))
                .fontSize(FontSize.CAPTION)
                .fontColor($r('app.color.text_tertiary'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            if (v.commitUrl !== '') {
              SymbolGlyph($r('sys.symbol.hammer_fill'))
                .fontSize(16)
                .fontColor([$r('app.color.cyan')])
            }
          }
          .width('100%')
          .padding({ left: Space.L, right: Space.L, top: Space.M, bottom: Space.M })
          .onClick(() => Nav.openWeb(this.app.name, v.commitUrl))

          if (i < Math.min(this.app.versions.length, MAX_VERSIONS) - 1) {
            Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: Space.L })
          }
        }
      }, (v: VersionInfo) => v.versionCode.toString())
    }
    .card()
    .margin({ left: Space.GUTTER, right: Space.GUTTER })
  }

  copy(text: string): void {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      AppContext.toast($r('app.string.copied'));
    }).catch(() => {
    });
  }
}
