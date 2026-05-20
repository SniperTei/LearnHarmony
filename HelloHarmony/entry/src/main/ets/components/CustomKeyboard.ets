/** 键盘按键布局 */
const KEY_ROWS: string[][] = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
  ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
  ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
  ['z', 'x', 'c', 'v', 'b', 'n', 'm', 'DEL'],
]

/**
 * 自定义键盘组件
 *
 * Usage:
 * ```
 * CustomKeyboard({
 *   onKeyPress: (key: string) => { ... },
 *   onDone: () => { ... }
 * })
 * ```
 */
@Component
export struct CustomKeyboard {
  onKeyPress: (key: string) => void = (_key: string) => {}
  onDone: () => void = () => {}

  build() {
    Column() {
      // 完成按钮
      Row() {
        Blank()
        Text('完成')
          .fontSize(14)
          .fontColor('#3370FF')
          .padding({ left: 16, top: 8, bottom: 8 })
          .onClick(() => this.onDone())
      }
      .width('100%')

      // 按键区域
      ForEach(KEY_ROWS, (row: string[], rowIndex: number) => {
        Row({ space: 4 }) {
          ForEach(row, (key: string) => {
            Column() {
              if (key === 'DEL') {
                Text('⌫')
                  .fontSize(18)
                  .fontColor('#333333')
              } else {
                Text(key)
                  .fontSize(16)
                  .fontColor('#333333')
              }
            }
            .height(36)
            .layoutWeight(key === 'DEL' ? 1.5 : 1)
            .justifyContent(FlexAlign.Center)
            .borderRadius(6)
            .backgroundColor(key === 'DEL' ? '#E8E8E8' : '#F7F8FA')
            .onClick(() => this.onKeyPress(key))
          }, (key: string) => key)
        }
        .width('100%')
        .margin({ bottom: 4 })
      }, (_row: string[], index: number) => index.toString())
    }
    .width('100%')
    .padding({ left: 8, right: 8, bottom: 8 })
  }
}
