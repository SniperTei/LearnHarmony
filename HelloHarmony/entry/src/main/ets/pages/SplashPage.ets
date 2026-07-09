/**
 * 闪屏页
 * TODO: 加载应用资源 → 跳转 WebView 主页面
 */
@Component
export struct SplashPage {
  @State progress: number = 0

  build() {
    NavDestination() {
      Column() {
        Text('HelloHarmony')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        // TODO: 加载进度条 / 广告位
        Text('加载中...')
          .fontSize(16)
          .fontColor('#999999')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
    }
    .hideTitleBar(true)
  }
}
