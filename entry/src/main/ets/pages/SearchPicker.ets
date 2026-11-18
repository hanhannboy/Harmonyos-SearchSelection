import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SearchSkill, buildSearchUrl, extractHost } from '../model/SkillTypes';
import { loadSkills } from '../model/SkillStore';

@Entry({ useSharedStorage: true })
@Component
struct SearchPicker {
  @LocalStorageProp('searchText') searchText: string = '';
  @State searchSkills: SearchSkill[] = [];
  @StorageProp('safeTopVp') safeTopVp: number = 0;
  @StorageProp('safeBottomVp') safeBottomVp: number = 0;

  aboutToAppear(): void {
    loadSkills(this.abilityContext())
      .then((skills: SearchSkill[]) => {
        this.searchSkills = skills;
      })
      .catch((err: BusinessError) => {
        this.showToast(`加载技能失败：${err.message}`);
      });
  }

  private abilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message, duration: 2500 });
  }

  private closeSelf(): void {
    this.abilityContext().terminateSelf();
  }

  onBackPress(): boolean {
    this.closeSelf();
    return true;
  }

  private launchUrl(targetUrl: string): void {
    this.abilityContext().openLink(targetUrl, { appLinkingOnly: false })
      .then(() => {
        this.closeSelf();
      })
      .catch((err: BusinessError) => {
        this.showToast(`跳转失败：${err.message}`);
      });
  }

  private runSkill(skill: SearchSkill): void {
    if (this.searchText.trim().length === 0) {
      this.showToast('没有收到文本内容');
      return;
    }
    this.launchUrl(buildSearchUrl(skill.urlTemplate, this.searchText));
  }

  build() {
    Column({ space: 12 }) {
      Text('选择一个技能搜索')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 12 })

      Column({ space: 4 }) {
        Text('选中文本')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Text(this.searchText.length > 0 ? this.searchText : '（未收到文本内容）')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .copyOption(CopyOptions.LocalDevice)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(12)
      .borderRadius(12)
      .backgroundColor($r('app.color.sheet_card_bg'))

      if (this.searchSkills.length === 0) {
        Column({ space: 10 }) {
          Text('还没有技能，先去应用里创建一个吧')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
          Button('打开 ShareRunner')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              const ctx = this.abilityContext();
              const want: Want = {
                bundleName: ctx.abilityInfo.bundleName,
                abilityName: 'EntryAbility'
              };
              ctx.startAbility(want)
                .then(() => {
                  this.closeSelf();
                })
                .catch((err: BusinessError) => {
                  this.showToast(`打开应用失败：${err.message}`);
                });
            })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      } else {
        List({ space: 8 }) {
          ForEach(this.searchSkills, (item: SearchSkill) => {
            ListItem() {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text(item.skillName)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text(extractHost(item.urlTemplate))
                    .fontSize(11)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('›')
                  .fontSize(20)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .padding(12)
              .borderRadius(12)
              .backgroundColor($r('app.color.sheet_card_bg'))
              .onClick(() => {
                this.runSkill(item);
              })
            }
          }, (item: SearchSkill) => item.skillId)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      Button('关闭')
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.sheet_card_bg'))
        .onClick(() => {
          this.closeSelf();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: this.safeTopVp + 24, bottom: this.safeBottomVp + 16 })
    .backgroundColor($r('app.color.share_panel_bg'))
  }
}