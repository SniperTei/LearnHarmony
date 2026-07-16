/**
 * 插件选项
 *
 * 一个 pluginId + pluginName 对应网格里的一个卡片。
 * 若数据来自服务端 JSON，按下面循环转成 PluginOption[] 即可。
 */
export class PluginOption {
  pluginId: string
  pluginName: string

  constructor(pluginId: string, pluginName: string) {
    this.pluginId = pluginId
    this.pluginName = pluginName
  }

  /**
   * 从原始对象数组构造（方便对接服务端 JSON）。
   *
   * 用法：
   * ```
   * const raw = JSON.parse(jsonStr) as Record<string, Object>[]
   * const plugins = PluginOption.fromList(raw)
   * ```
   */
  static fromList(items: Record<string, Object>[]): PluginOption[] {
    const list: PluginOption[] = []
    for (let i = 0; i < items.length; i++) {
      const id = items[i]['pluginId'] as string ?? ''
      const name = items[i]['pluginName'] as string ?? ''
      list.push(new PluginOption(id, name))
    }
    return list
  }
}

/**
 * 插件选择器配置
 */
export class PluginPickerConfig {
  title: string = '请选择需要使用的插件'
  confirmText: string = '确定'
  cancelText: string = '取消'
  /** 列数，默认 2 列 */
  columns: number = 2
  /** 最大可见行数，超过即滚动（默认 4 行 = 2 列时 8 项） */
  maxRows: number = 4
}

/**
 * 插件选择底部弹窗（单选）。
 *
 * iOS 里对应 UICollectionView + 底部弹窗；鸿蒙里用 Grid 实现。
 *
 * 用法：
 * ```
 * // 1. 页面里声明状态
 * @State showPicker: boolean = false
 * @State plugins: PluginOption[] = [
 *   new PluginOption('zhengnan', '插件A'),
 *   new PluginOption('zhengbei', '插件B'),
 * ]
 *
 * // 2. 在 build 里挂载（show 由父组件控制，关闭时在回调里置 false）
 * PluginPicker({
 *   show: this.showPicker,
 *   config: new PluginPickerConfig(),
 *   plugins: this.plugins,
 *   onConfirm: (pluginId: string) => {
 *     this.showPicker = false
 *     hilog.info(0, 'TAG', `选中插件: ${pluginId}`)
 *   },
 *   onCancel: () => {
 *     this.showPicker = false
 *   }
 * })
 *
 * // 3. 触发显示
 * Button('选择插件').onClick(() => this.showPicker = true)
 * ```
 *
 * 说明：show 是父组件控制的单向数据源，关闭弹窗请务必在 onConfirm / onCancel
 * 里把 show 置回 false（点击遮罩 / ✕ / 取消按钮都会触发 onCancel）。
 */
@Component
export struct PluginPicker {
  @Prop show: boolean = false
  config: PluginPickerConfig = new PluginPickerConfig()
  @Prop plugins: PluginOption[] = []
  onConfirm: (pluginId: string) => void = (_id: string) => {}
  onCancel: () => void = () => {}

  @State private selectedId: string = ''

  // 网格尺寸常量
  private readonly ROW_HEIGHT: number = 56
  private readonly ROW_GAP: number = 12

  /** 列模板字符串，如 '1fr 1fr' */
  private columnsTemplate(): string {
    const n = Math.max(1, this.config.columns)
    const parts: string[] = []
    for (let i = 0; i < n; i++) {
      parts.push('1fr')
    }
    return parts.join(' ')
  }

  /** 网格最大高度 = 行高 * 行数 + 行间距 */
  private maxGridHeight(): number {
    const rows = Math.max(1, this.config.maxRows)
    return rows * this.ROW_HEIGHT + (rows - 1) * this.ROW_GAP
  }

  private isSelected(p: PluginOption): boolean {
    return this.selectedId === p.pluginId
  }

  private dismiss(): void {
    this.onCancel()
  }

  build() {
    if (this.show) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 半透明背景遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(0.4)
          .transition(TransitionEffect.OPACITY)
          .onClick(() => this.dismiss())

        // 底部弹窗卡片
        Column() {
          // 顶部拖拽指示条
          Row() {
            Column()
              .width(36)
              .height(4)
              .borderRadius(2)
              .backgroundColor('#E5E6EB')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 10, bottom: 6 })

          // 标题栏
          Row() {
            Text(this.config.title)
              .fontSize(17)
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
            .onClick(() => this.dismiss())
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 12 })

          if (this.plugins.length === 0) {
            // 空态
            Text('暂无可选插件')
              .fontSize(14)
              .fontColor('#C9CDD4')
              .margin({ top: 40, bottom: 40 })
          } else {
            // 插件网格：只设 columnsTemplate、不设 rowsTemplate，
            // 超过 maxRows 时自动纵向滚动。
            Grid() {
              ForEach(this.plugins, (p: PluginOption) => {
                GridItem() {
                  Column() {
                    Text(p.pluginName)
                      .fontSize(15)
                      .fontColor(this.isSelected(p) ? '#3370FF' : '#1D2129')
                      .fontWeight(this.isSelected(p) ? FontWeight.Medium : FontWeight.Normal)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height(this.ROW_HEIGHT)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(10)
                  .backgroundColor(this.isSelected(p) ? '#EBF3FF' : '#F7F8FA')
                  .border({
                    width: this.isSelected(p) ? 1.5 : 0,
                    color: '#3370FF',
                    style: BorderStyle.Solid,
                    radius: 10
                  })
                  .onClick(() => { this.selectedId = p.pluginId })
                }
              }, (p: PluginOption) => p.pluginId)
            }
            .columnsTemplate(this.columnsTemplate())
            .columnsGap(this.ROW_GAP)
            .rowsGap(this.ROW_GAP)
            .padding({ left: 20, right: 20 })
            .scrollBar(BarState.Auto)
            .constraintSize({ maxHeight: this.maxGridHeight() })
          }

          // 底部按钮
          Row({ space: 12 }) {
            Button(this.config.cancelText)
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .fontColor('#4E5969')
              .backgroundColor('#F2F3F5')
              .borderRadius(22)
              .onClick(() => this.dismiss())

            Button(this.config.confirmText)
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .fontColor(Color.White)
              .backgroundColor(this.selectedId.length > 0 ? '#3370FF' : '#BBDAFF')
              .borderRadius(22)
              .enabled(this.selectedId.length > 0)
              .onClick(() => {
                this.onConfirm(this.selectedId)
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM))
      }
      .width('100%')
      .height('100%')
    }
  }
}
