import { util } from '@kit.ArkTS';

export const QUERY_PLACEHOLDER = '%s';

@Observed
export class SearchSkill {
  skillId: string;
  skillName: string;
  urlTemplate: string;

  constructor(skillId: string, skillName: string, urlTemplate: string) {
    this.skillId = skillId;
    this.skillName = skillName;
    this.urlTemplate = urlTemplate;
  }
}

export interface SkillRecord {
  skillId: string;
  skillName: string;
  urlTemplate: string;
}

export function createSkillId(): string {
  return util.generateRandomUUID(false);
}

export function buildSearchUrl(urlTemplate: string, rawText: string): string {
  const keyword = encodeURIComponent(rawText.trim());
  return urlTemplate.split(QUERY_PLACEHOLDER).join(keyword);
}

export function validateSkillTemplate(urlTemplate: string): string {
  const trimmed = urlTemplate.trim();
  if (trimmed.length === 0) {
    return '请输入链接模板';
  }
  if (!trimmed.includes(QUERY_PLACEHOLDER)) {
    return `链接中需要包含占位符 ${QUERY_PLACEHOLDER}`;
  }
  if (!/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(trimmed)) {
    return '链接需要以协议开头，例如 https://';
  }
  return '';
}

export function extractHost(urlTemplate: string): string {
  const match = urlTemplate.match(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\/([^/?#]+)/);
  return match !== null ? match[1] : urlTemplate;
}

export function createPresetSkills(): SearchSkill[] {
  return [
    new SearchSkill(createSkillId(), '百度搜索', 'https://www.baidu.com/s?wd=%s'),
    new SearchSkill(createSkillId(), '必应搜索', 'https://www.bing.com/search?q=%s'),
    new SearchSkill(createSkillId(), '知乎搜索', 'https://www.zhihu.com/search?type=content&q=%s'),
    new SearchSkill(createSkillId(), '哔哩哔哩', 'https://search.bilibili.com/all?keyword=%s'),
    new SearchSkill(createSkillId(), '淘宝搜索', 'https://s.taobao.com/search?q=%s')
  ];
}