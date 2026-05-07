/**
 * 通用页面状态组件
 * 提供加载中、空数据等标准化展示
 */

/** 全屏加载遮罩，覆盖整个页面（含导航栏），阻止所有操作 */
@Component
export struct LoadingOverlay {
  @Prop message: string = '加载中...'

  build() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007DFF')
      Text(this.message)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.4)')
  }
}

/** 空数据状态 */
@Component
export struct EmptyState {
  @Prop message: string = '暂无数据'

  build() {
    Column() {
      Text(this.message)
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(40)
  }
}
