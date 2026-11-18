import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { applyImmersiveChrome } from '../common/WindowChrome';

const SEARCH_TAG: string = 'SearchAbility';
const TEXT_PARAM_KEYS: string[] = ['query', 'key_text', 'text', 'selectedText', 'keyword', 'content', 'searchText'];

function extractSearchText(want: Want): string {
  const params = want.parameters;
  if (params !== undefined) {
    for (const key of TEXT_PARAM_KEYS) {
      const raw: Object | undefined = params[key];
      if (typeof raw === 'string' && raw.trim().length > 0) {
        return raw;
      }
    }
  }
  if (want.uri !== undefined && want.uri.length > 0) {
    return want.uri;
  }
  return '';
}

export default class SearchAbility extends UIAbility {
  private searchStorage: LocalStorage = new LocalStorage();
  private mainWindow: window.Window | null = null;
  private terminateTimer: number = -1;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0001, SEARCH_TAG, 'onCreate want: %{public}s', JSON.stringify(want));
    this.searchStorage.setOrCreate('searchText', extractSearchText(want));
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0001, SEARCH_TAG, 'onNewWant want: %{public}s', JSON.stringify(want));
    this.searchStorage.setOrCreate('searchText', extractSearchText(want));
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.mainWindow = windowStage.getMainWindowSync();
    windowStage.loadContent('pages/SearchPicker', this.searchStorage, (err) => {
      if (err.code) {
        hilog.error(0x0001, SEARCH_TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      applyImmersiveChrome(this.mainWindow, this.context);
    });
  }

  onConfigurationUpdate(): void {
    applyImmersiveChrome(this.mainWindow, this.context);
  }

  onBackground(): void {
    hilog.info(0x0001, SEARCH_TAG, 'onBackground, schedule terminate');
    this.terminateTimer = setTimeout(() => {
      hilog.info(0x0001, SEARCH_TAG, 'terminate timer fired');
      this.terminateTimer = -1;
      this.context.terminateSelf()
        .then(() => {
          hilog.info(0x0001, SEARCH_TAG, 'terminateSelf resolved');
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0001, SEARCH_TAG, 'terminateSelf failed: %{public}d %{public}s', err.code, err.message);
        });
    }, 600);
  }

  onForeground(): void {
    hilog.info(0x0001, SEARCH_TAG, 'onForeground, timer=%{public}d', this.terminateTimer);
    if (this.terminateTimer >= 0) {
      clearTimeout(this.terminateTimer);
      this.terminateTimer = -1;
    }
  }
}
