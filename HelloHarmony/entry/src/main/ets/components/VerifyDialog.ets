import { CustomKeyboard } from './CustomKeyboard'

/**
 * Verify Dialog Config
 */
export class VerifyDialogConfig {
  title: string = '身份验证'
  umLabel: string = 'UM验证'
  faceLabel: string = '人脸识别'
  umPlaceholder: string = '请输入UM账号'
  passwordPlaceholder: string = '请输入密码'
  captchaPlaceholder: string = '请输入验证码'
  umButtonText: string = '验证'
  faceButtonText: string = '开始识别'
  faceDescription: string = '为了您的账户安全，请完成人脸识别'
  defaultTab: number = 0
  /**
   * "Y" = show both UM verification and face recognition tabs
   * "N" or empty = show only face recognition (no tabs)
   */
  passwordFlag: string = 'Y'
  /** 密码错误达到此次数后展示验证码，默认 3 次 */
  captchaThreshold: number = 1
}

/**
 * Verify Dialog (full-screen overlay)
 */
@Component
export struct VerifyDialog {
  show: boolean = false
  config: VerifyDialogConfig = new VerifyDialogConfig()
  onUmVerify: (account: string, password: string, captcha: string, onFailed: () => void) => void =
    (_account: string, _password: string, _captcha: string, _onFailed: () => void) => {}
  onFaceVerify: () => void = () => {}

  @State private currentTab: number = 0
  @State private umAccount: string = ''
  @State private umPassword: string = ''
  @State private captchaCode: string = ''
  @State private showCaptcha: boolean = false
  @State private showKeyboard: boolean = false
  private failedCount: number = 0

  private showPasswordTab(): boolean {
    return this.config.passwordFlag === 'Y'
  }

  onPasswordFailed(): void {
    this.failedCount++
    if (this.failedCount >= this.config.captchaThreshold) {
      this.showCaptcha = true
    }
  }

  resetFailedCount(): void {
    this.failedCount = 0
    this.showCaptcha = false
    this.captchaCode = ''
  }

  private onKeyPress(key: string): void {
    if (key === 'DEL') {
      if (this.umPassword.length > 0) {
        this.umPassword = this.umPassword.substring(0, this.umPassword.length - 1)
      }
    } else {
      this.umPassword += key
    }
  }

  aboutToAppear(): void {
    if (this.showPasswordTab()) {
      this.currentTab = this.config.defaultTab
    } else {
      this.currentTab = 1
    }
  }

  build() {
    Stack() {
      // 半透明背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .opacity(0.4)
        .onClick(() => {
          this.showKeyboard = false
          this.show = false
        })

      // 弹窗内容
      Column() {
        // 上方区域：弹窗卡片
        Stack() {
          // 透明全屏遮罩 - 键盘弹出时覆盖整个弹窗卡片区域，点击关闭键盘
          if (this.showKeyboard) {
            Column()
              .width('100%')
              .height('100%')
              .hitTestBehavior(this.showKeyboard ? HitTestMode.Default : HitTestMode.None)
              .onClick(() => {
                this.showKeyboard = false
              })
          }

          // 弹窗内容卡片
          Column() {
            // Title bar
            Row() {
              Text(this.config.title)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1D2129')

              Blank()

              Stack() {
                Text('✕')
                  .fontSize(14)
                  .fontColor('#86909C')
              }
              .width(28)
              .height(28)
              .borderRadius(14)
              .backgroundColor('#F2F3F5')
              .alignContent(Alignment.Center)
              .onClick(() => {
                this.showKeyboard = false
                this.show = false
              })
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 24 })

            // Tab bar
            if (this.showPasswordTab()) {
              Row() {
                Column() {
                  Text(this.config.umLabel)
                    .fontSize(15)
                    .fontColor(this.currentTab === 0 ? '#3370FF' : '#86909C')
                    .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
                }
                .layoutWeight(1)
                .height(44)
                .justifyContent(FlexAlign.Center)
                .borderRadius(8)
                .backgroundColor(this.currentTab === 0 ? '#EBF3FF' : Color.Transparent)
                .onClick(() => {
                  this.showKeyboard = false
                  this.currentTab = 0
                })

                Blank()
                  .width(12)

                Column() {
                  Text(this.config.faceLabel)
                    .fontSize(15)
                    .fontColor(this.currentTab === 1 ? '#3370FF' : '#86909C')
                    .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
                }
                .layoutWeight(1)
                .height(44)
                .justifyContent(FlexAlign.Center)
                .borderRadius(8)
                .backgroundColor(this.currentTab === 1 ? '#EBF3FF' : Color.Transparent)
                .onClick(() => {
                  this.showKeyboard = false
                  this.currentTab = 1
                })
              }
              .width('100%')
              .padding({ left: 24, right: 24 })
              .margin({ top: 16 })
              .backgroundColor('#F7F8FA')
              .borderRadius(8)
            }

            // Tab content
            if (this.currentTab === 0) {
              this.UmVerifyContent()
            } else {
              this.FaceVerifyContent()
            }

            // Action button
            Button(!this.showPasswordTab() || this.currentTab === 1
              ? this.config.faceButtonText : this.config.umButtonText)
              .width('100%')
              .height(48)
              .backgroundColor('#3370FF')
              .borderRadius(24)
              .fontSize(16)
              .fontColor(Color.White)
              .margin({ left: 24, right: 24, bottom: 24, top: 24 })
              .onClick(() => {
                this.showKeyboard = false
                if (this.showPasswordTab() && this.currentTab === 0) {
                  this.onUmVerify(this.umAccount, this.umPassword, this.captchaCode, () => {
                    this.onPasswordFailed()
                  })
                } else {
                  this.onFaceVerify()
                }
              })
          }
          .width('85%')
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .layoutWeight(1)

        // 自定义键盘 - 固定在底部
        if (this.showKeyboard) {
          Column() {
            CustomKeyboard({
              onKeyPress: (key: string) => this.onKeyPress(key),
              onDone: () => { this.showKeyboard = false }
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  UmVerifyContent() {
    Column() {
      Column() {
        Text('UM账号')
          .fontSize(12)
          .fontColor('#86909C')
          .margin({ bottom: 6 })
        TextInput({ placeholder: this.config.umPlaceholder, text: this.umAccount })
          .height(44)
          .fontSize(14)
          .fontColor('#1D2129')
          .placeholderColor('#C9CDD4')
          .backgroundColor('#F7F8FA')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.umAccount = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 20 })

      Column() {
        Text('密码')
          .fontSize(12)
          .fontColor('#86909C')
          .margin({ bottom: 6 })
        Row() {
          if (this.umPassword.length > 0) {
            Text('•'.repeat(this.umPassword.length))
              .fontSize(16)
              .fontColor('#1D2129')
              .lineHeight(44)
          } else {
            Text(this.config.passwordPlaceholder)
              .fontSize(14)
              .fontColor('#C9CDD4')
              .lineHeight(44)
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor('#F7F8FA')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .border({
          width: this.showKeyboard ? 2 : 0,
          color: '#3370FF',
          style: BorderStyle.Solid,
          radius: 8
        })
        .onClick(() => {
          this.showKeyboard = !this.showKeyboard
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 16 })

      // 验证码区域
      if (this.showCaptcha) {
        Column() {
          Text('验证码')
            .fontSize(12)
            .fontColor('#86909C')
            .margin({ bottom: 6 })
          Row() {
            TextInput({ placeholder: this.config.captchaPlaceholder, text: this.captchaCode })
              .height(44)
              .fontSize(14)
              .fontColor('#1D2129')
              .placeholderColor('#C9CDD4')
              .backgroundColor('#F7F8FA')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.captchaCode = value
              })

            Stack() {
              Text('CAPTCHA')
                .fontSize(11)
                .fontColor('#C9CDD4')
            }
            .width(100)
            .height(44)
            .borderRadius(8)
            .backgroundColor('#F2F3F5')
            .margin({ left: 8 })
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 16 })
      }
    }
    .padding({ left: 24, right: 24 })
  }

  @Builder
  FaceVerifyContent() {
    Column() {
      Text(this.config.faceDescription)
        .fontSize(14)
        .fontColor('#86909C')
        .margin({ top: 24 })

      Stack() {
        Circle({ width: 140, height: 140 })
          .fill('#EBF3FF')
          .stroke('#3370FF')
          .strokeWidth(3)

        Circle({ width: 44, height: 44 })
          .fill('#3370FF')
          .opacity(0.25)

        Circle({ width: 72, height: 36 })
          .fill('#3370FF')
          .opacity(0.15)
          .position({ x: '50%', y: '72%' })
          .translate({ x: '-50%', y: '-50%' })
      }
      .width(140)
      .height(140)
      .margin({ top: 28 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
