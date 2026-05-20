import { scanBarcode } from '@kit.ScanKit'
import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'QrScanPage'

/** 扫码结果回调 */
export class QrScanCallback {
  static callback: ((value: string) => void) | null = null
}

@Entry
@Component
struct QrScanPage {
  @State private scanning: boolean = false
  @State private result: string = ''
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#3370FF')
          .onClick(() => router.back())
        Blank()
        Text('扫一扫')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D2129')
        Blank()
        Text('< 返回')
          .fontSize(16)
          .fontColor(Color.Transparent)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      Column() {
        if (this.result) {
          Text(`扫码结果: ${this.result}`)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ bottom: 24 })

          Button('返回')
            .onClick(() => {
              if (QrScanCallback.callback) {
                QrScanCallback.callback(this.result)
              }
              router.back()
            })
        } else {
          Text('点击下方按钮开始扫码')
            .fontSize(16)
            .fontColor('#86909C')
            .margin({ bottom: 32 })

          Button(this.scanning ? '扫码中...' : '开始扫码')
            .width(200)
            .height(48)
            .fontSize(16)
            .backgroundColor('#3370FF')
            .borderRadius(24)
            .enabled(!this.scanning)
            .onClick(() => this.startScan())
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private async startScan(): Promise<void> {
    this.scanning = true
    try {
      const options: scanBarcode.ScanOptions = {
        enableMultiMode: false,
        enableAlbum: true
      }
      const scanResult = await scanBarcode.startScanForResult(this.context, options)
      if (scanResult && scanResult.originalValue) {
        this.result = scanResult.originalValue
        hilog.info(0, TAG, `扫码成功: ${this.result}`)
      } else {
        hilog.info(0, TAG, '扫码取消')
      }
    } catch (e) {
      hilog.error(0, TAG, `扫码失败: ${(e as Error).message}`)
    } finally {
      this.scanning = false
    }
  }
}
