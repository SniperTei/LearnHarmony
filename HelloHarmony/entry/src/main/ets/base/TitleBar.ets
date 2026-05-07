/**
 * 通用顶部导航栏
 * 支持标题、返回按钮、加载指示器
 */
@Component
export struct TitleBar {
  @Prop title: string = ''
  @Prop showBack: boolean = false
  @Prop showLoading: boolean = false
  @Prop showSetting: boolean = false
  onSettingClick?: () => void

  build() {
    Row() {
      if (this.showBack) {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => this.getUIContext().getRouter().back())
      }
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ left: this.showBack ? 16 : 0 })
      Blank()
      if (this.showLoading) {
        LoadingProgress()
          .width(20)
          .height(20)
          .color('#007DFF')
          .margin({ right: 12 })
      }
      if (this.showSetting) {
        Text('设置')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => {
            if (this.onSettingClick) {
              this.onSettingClick()
            }
          })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F5F5F5')
  }
}
