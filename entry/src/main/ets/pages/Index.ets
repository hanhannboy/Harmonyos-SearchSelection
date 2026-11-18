import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SearchSkill, buildSearchUrl, createSkillId, extractHost, validateSkillTemplate, QUERY_PLACEHOLDER } from '../model/SkillTypes';
import { loadSkills, saveSkills } from '../model/SkillStore';

@Component
struct SkillRowView {
  @ObjectLink skillItem: SearchSkill;
  onRunSkill: (skill: SearchSkill) => void = () => {};
  onEditSkill: (skill: SearchSkill) => void = () => {};

  build() {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text(this.skillItem.skillName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(extractHost(this.skillItem.urlTemplate))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('搜索')
        .fontSize(13)
        .height(32)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.accent'))
        .onClick(() => {
          this.onRunSkill(this.skillItem);
        })
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor($r('app.color.sheet_card_bg'))
    .onClick(() => {
      this.onEditSkill(this.skillItem);
    })
  }
}

@Entry
@Component
struct Index {
  @State skillList: SearchSkill[] = [];
  @State testText: string = '';
  @State showEditor: boolean = false;
  @State editName: string = '';
  @State editUrl: string = '';
  @State editError: string = '';
  @StorageProp('safeTopVp') safeTopVp: number = 0;
  @StorageProp('safeBottomVp') safeBottomVp: number = 0;
  private editingSkill: SearchSkill | null = null;

  aboutToAppear(): void {
    loadSkills(this.hostContext())
      .then((skills: SearchSkill[]) => {
        this.skillList = skills;
      })
      .catch((err: BusinessError) => {
        this.showToast(`加载技能失败：${err.message}`);
      });
  }

  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message, duration: 2500 });
  }

  private persist(): void {
    saveSkills(this.hostContext(), this.skillList)
      .catch((err: BusinessError) => {
        this.showToast(`保存失败：${err.message}`);
      });
  }

  private runSkill(skill: SearchSkill): void {
    if (this.testText.trim().length === 0) {
      this.showToast('请先在上方输入测试文本');
      return;
    }
    const targetUrl = buildSearchUrl(skill.urlTemplate, this.testText);
    this.hostContext().openLink(targetUrl, { appLinkingOnly: false })
      .catch((err: BusinessError) => {
        this.showToast(`无法打开链接：${err.message}`);
      });
  }

  private openEditor(skill: SearchSkill | null): void {
    this.editingSkill = skill;
    this.editName = skill !== null ? skill.skillName : '';
    this.editUrl = skill !== null ? skill.urlTemplate : '';
    this.editError = '';
    this.showEditor = true;
  }

  private saveEditor(): void {
    const trimmedName = this.editName.trim();
    if (trimmedName.length === 0) {
      this.editError = '请输入技能名称';
      return;
    }
    const templateError = validateSkillTemplate(this.editUrl);
    if (templateError.length > 0) {
      this.editError = templateError;
      return;
    }
    const trimmedUrl = this.editUrl.trim();
    if (this.editingSkill !== null) {
      this.editingSkill.skillName = trimmedName;
      this.editingSkill.urlTemplate = trimmedUrl;
    } else {
      this.skillList.push(new SearchSkill(createSkillId(), trimmedName, trimmedUrl));
    }
    this.persist();
    this.showEditor = false;
  }

  private confirmRemove(skill: SearchSkill): void {
    this.getUIContext().showAlertDialog({
      title: '删除技能',
      message: `确定删除「${skill.skillName}」吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.danger'),
        action: () => {
          const index = this.skillList.findIndex((item: SearchSkill): boolean => item.skillId === skill.skillId);
          if (index >= 0) {
            this.skillList.splice(index, 1);
            this.persist();
          }
        }
      }
    });
  }

  @Builder
  DeleteAction(skill: SearchSkill) {
    Button('删除')
      .fontSize(13)
      .height('100%')
      .width(72)
      .fontColor(Color.White)
      .backgroundColor($r('app.color.danger'))
      .borderRadius(12)
      .onClick(() => {
        this.confirmRemove(skill);
      })
  }

  @Builder
  EditorSheet() {
    Column({ space: 14 }) {
      Text(this.editingSkill !== null ? '编辑技能' : '新建技能')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 8 })

      Column({ space: 6 }) {
        Text('技能名称')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        TextInput({ placeholder: '例如：百度搜索', text: $$this.editName })
          .maxLength(30)
          .backgroundColor($r('app.color.share_panel_bg'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('搜索链接模板')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        TextInput({ placeholder: 'https://www.baidu.com/s?wd=%s', text: $$this.editUrl })
          .backgroundColor($r('app.color.share_panel_bg'))
        Text(`用 ${QUERY_PLACEHOLDER} 代表分享的文本，执行时会自动替换并做 URL 编码。打开哪个应用由系统决定。`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if (this.editError.length > 0) {
        Text(this.editError)
          .fontSize(13)
          .fontColor($r('app.color.danger'))
      }

      Button('保存')
        .width('100%')
        .fontColor(Color.White)
        .backgroundColor($r('app.color.accent'))
        .onClick(() => {
          this.saveEditor();
        })
    }
    .padding({ left: 20, right: 20, bottom: 24 })
    .width('100%')
  }

  build() {
    Column({ space: 14 }) {
      Column({ space: 4 }) {
        Text('文本选择搜索')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('分享文本进来，选一个技能，立即跳转搜索')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('测试文本')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        TextInput({ placeholder: '输入文本后，点击技能右侧「搜索」试试', text: $$this.testText })
          .backgroundColor($r('app.color.sheet_card_bg'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row() {
        Text(`搜索引擎（${this.skillList.length}）`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Button('+ 新建')
          .fontSize(13)
          .height(32)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.accent'))
          .onClick(() => {
            this.openEditor(null);
          })
      }
      .width('100%')

      if (this.skillList.length === 0) {
        Column({ space: 8 }) {
          Text('还没有技能')
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
          Text('点击右上角「新建」，把一个搜索链接封装成搜索引擎')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding({ top: 40, bottom: 40 })
      } else {
        List({ space: 10 }) {
          ForEach(this.skillList, (item: SearchSkill) => {
            ListItem() {
              SkillRowView({
                skillItem: item,
                onRunSkill: (skill: SearchSkill) => {
                  this.runSkill(skill);
                },
                onEditSkill: (skill: SearchSkill) => {
                  this.openEditor(skill);
                }
              })
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.DeleteAction(item);
                }
              }
            })
          }, (item: SearchSkill) => item.skillId)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: this.safeTopVp + 16, bottom: this.safeBottomVp + 16 })
    .backgroundColor($r('app.color.share_panel_bg'))
    .bindSheet($$this.showEditor, this.EditorSheet(), {
      height: 420,
      dragBar: true,
      showClose: true,
      backgroundColor: $r('app.color.sheet_card_bg')
    })
  }
}