import { SNPPage } from './SNPPage'
import { DeviceAuth } from '../pages/DeviceAuth'
import { QrScanPage } from '../pages/QrScanPage'
import { ZhengTest } from '../pages/ZhengTest'
import { SplashPage } from '../pages/SplashPage'

/**
 * 全局页面映射 @Builder
 * Navigation.navDestination(PageMap) 会根据 name 渲染对应组件
 */
@Builder
export function PageMap(name: string) {
  if (name === SNPPage.DeviceAuth) {
    DeviceAuth()
  } else if (name === SNPPage.QrScanPage) {
    QrScanPage()
  } else if (name === SNPPage.ZhengTest) {
    ZhengTest()
  } else if (name === SNPPage.SplashPage) {
    SplashPage()
  }
}
