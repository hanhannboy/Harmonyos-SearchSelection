import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ShareExtAbility';

function extractSharedText(data: systemShare.SharedData): string {
  const records = data.getRecords();
  for (const record of records) {
    const content = record.content ?? '';
    if (content.length > 0) {
      return content;
    }
  }
  for (const record of records) {
    const title = record.title ?? '';
    if (title.length > 0) {
      return title;
    }
    const uri = record.uri ?? '';
    if (uri.length > 0) {
      return uri;
    }
  }
  return '';
}

export default class ShareExtAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        const utdList: string[] = data.getRecords().map((record: systemShare.SharedRecord): string => record.utd);
        hilog.info(0x0000, TAG, 'shared utds: %{public}s', utdList.join(','));
        const sharedText = extractSharedText(data);
        const storage = new LocalStorage();
        storage.setOrCreate('sharedText', sharedText);
        storage.setOrCreate('shareSession', session);
        session.loadContent('pages/SharePicker', storage);
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, TAG, 'getSharedData failed: %{public}s', err.message);
        session.terminateSelf();
      });
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    hilog.info(0x0000, TAG, '%{public}s', 'share session destroyed');
  }
}