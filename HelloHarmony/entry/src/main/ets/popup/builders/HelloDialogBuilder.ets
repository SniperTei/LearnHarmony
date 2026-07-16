import { PopupBuilder, PopupParams } from '../PopupBuilder'

/**
 * HelloDialog 的数据
 */
export interface HelloDialogData {
  title: string
  message: string
  confirmText?: string
  cancelText?: string
}

/**
 * HelloDialog 的内容 Builder（模块级 @Builder，被 wrapBuilder 包装）
 *
 * 注意：ArkUI 的 @Builder 必须是模块级函数或 struct 方法，不能写在 class 里。
 * 参数统一用 PopupParams（内部 data 字段转型为具体数据类型）。
 */
@Builder
function helloDialogBuilder(params: PopupParams) {
  Column() {
    // 标题
    Text((params.data as HelloDialogData).title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1D2129')
      .margin({ bottom: 12 })

    // 内容
    Text((params.data as HelloDialogData).message)
      .fontSize(14)
      .fontColor('#4E5969')
      .textAlign(TextAlign.Center)
      .lineHeight(22)
      .margin({ bottom: 20 })

    // 按钮区
    Row({ space: 12 }) {
      Button((params.data as HelloDialogData).cancelText ?? '取消')
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .fontColor('#4E5969')
        .backgroundColor('#F2F3F5')
        .borderRadius(20)
        .onClick(() => params.actions.cancel('cancel'))

      Button((params.data as HelloDialogData).confirmText ?? '确定')
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#3370FF')
        .borderRadius(20)
        .onClick(() => params.actions.confirm())
    }
    .width('100%')
  }
  .width('80%')
  .padding(24)
  .backgroundColor(Color.White)
  .borderRadius(16)
}

/**
 * HelloDialog 的 Builder 类
 *
 * 实现 PopupBuilder 接口，负责把 data + actions 包装成 WrappedBuilder。
 * PopupUtil 注册这个类，show('helloDialog', ...) 时调用它的 build()。
 */
export class HelloDialogBuilder implements PopupBuilder<HelloDialogData> {
  readonly type: string = 'helloDialog'

  build(): WrappedBuilder<[PopupParams]> {
    return wrapBuilder(helloDialogBuilder)
  }
}
