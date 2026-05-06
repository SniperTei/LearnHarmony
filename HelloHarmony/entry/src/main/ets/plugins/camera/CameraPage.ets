import { PluginPageSupport } from '../core/PluginPageSupport'

/**
 * 拍照页面
 * TODO: 实现自定义相机预览 + 拍照 + 压缩 + Base64
 */
@Entry
@Component
struct CameraPage {
  @State photoType: string = 'general'

  aboutToAppear() {
    const typeParam = PluginPageSupport.getParam<Object>('type', 'general')
    this.photoType = typeParam as string
  }

  build() {
    Column() {
      Text(`拍照类型: ${this.photoType}`)
        .fontSize(24)
        .margin({ bottom: 40 })

      Row({ space: 20 }) {
        Button('拍照成功（测试）')
          .onClick(() => {
            // TODO: 实际拍照 → 压缩 → Base64
            const data: Record<string, Object> = {}
            data['image'] = 'base64_data_placeholder'
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
