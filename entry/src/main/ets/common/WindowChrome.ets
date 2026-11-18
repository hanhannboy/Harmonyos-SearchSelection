import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WindowChrome';
const MAX_RETRY: number = 10;

export function applyImmersiveChrome(win: window.Window | null, context: common.UIAbilityContext, attempt: number = 0): void {
  if (win === null) {
    return;
  }
  win.setWindowLayoutFullScreen(true)
    .then(() => {
      const isDark: boolean = context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      const contentColor: string = isDark ? '#FFFFFF' : '#182431';
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: contentColor,
        navigationBarContentColor: contentColor
      })
        .then(() => {
          publishSafeInsets(win);
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0001, TAG, 'set system bar failed: %{public}s', err.message);
        });
    })
    .catch((err: BusinessError) => {
      if (attempt < MAX_RETRY) {
        setTimeout(() => {
          applyImmersiveChrome(win, context, attempt + 1);
        }, 100);
      } else {
        hilog.error(0x0001, TAG, 'set full screen failed: %{public}d %{public}s', err.code, err.message);
      }
    });
}

function publishSafeInsets(win: window.Window): void {
  const density: number = display.getDefaultDisplaySync().densityPixels;
  const sys = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
  const indicator = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
  AppStorage.setOrCreate('safeTopVp', sys.topRect.height / density);
  AppStorage.setOrCreate('safeBottomVp', Math.max(sys.bottomRect.height, indicator.bottomRect.height) / density);
}
