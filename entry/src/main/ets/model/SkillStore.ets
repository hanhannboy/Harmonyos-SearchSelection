import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SearchSkill, SkillRecord, createPresetSkills, QUERY_PLACEHOLDER } from './SkillTypes';

const STORE_NAME = 'sharerunner_skills';
const KEY_SKILLS = 'skills';
const TAG = 'SkillStore';

async function getStore(context: common.Context): Promise<preferences.Preferences> {
  return preferences.getPreferences(context, STORE_NAME);
}

export async function loadSkills(context: common.Context): Promise<SearchSkill[]> {
  const store = await getStore(context);
  const raw = await store.get(KEY_SKILLS, '') as string;
  if (raw.length === 0) {
    const presets = createPresetSkills();
    await saveSkills(context, presets);
    return presets;
  }
  try {
    const records = JSON.parse(raw) as SkillRecord[];
    return records.map((record: SkillRecord): SearchSkill =>
      new SearchSkill(record.skillId, record.skillName, record.urlTemplate.split('{query}').join(QUERY_PLACEHOLDER)));
  } catch (err) {
    const e = err as BusinessError;
    hilog.error(0x0000, TAG, 'Failed to parse skills: %{public}s', e.message);
    return [];
  }
}

export async function saveSkills(context: common.Context, skills: SearchSkill[]): Promise<void> {
  const records: SkillRecord[] = skills.map((skill: SearchSkill): SkillRecord => {
    const record: SkillRecord = {
      skillId: skill.skillId,
      skillName: skill.skillName,
      urlTemplate: skill.urlTemplate
    };
    return record;
  });
  const store = await getStore(context);
  await store.put(KEY_SKILLS, JSON.stringify(records));
  await store.flush();
}