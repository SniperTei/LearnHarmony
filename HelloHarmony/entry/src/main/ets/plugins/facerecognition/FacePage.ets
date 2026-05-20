import { PluginPageSupport } from '../core/PluginPageSupport'

/**
 * 人脸识别页面
 * TODO: 实现活体检测 + 人脸比对D
 */
@Entry
@Component
struct FacePage {
  @State verifyMode: string = 'liveness'

  aboutToAppear() {
    const modeParam = PluginPageSupport.getParam<Object>('mode', 'liveness')
    this.verifyMode = modeParam as string
  }

  build() {
    Column() {
      Text(`人脸识别模式: ${this.verifyMode}`)
        .fontSize(24)
        .margin({ bottom: 40 })

      Row({ space: 20 }) {
        Button('识别成功（测试）')
          .onClick(() => {
            // TODO: 实际活体检测 + 人脸比对
            const data: Record<string, Object> = {}
            data['score'] = 0.95
            PluginPageSupport.finishSuccess(data)
          })

        Button('取消')
          .onClick(() => {
            PluginPageSupport.finishError(-2, '用户取消')
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
