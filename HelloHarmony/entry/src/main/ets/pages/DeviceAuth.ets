import { HttpClientHolder } from 'network'
import { common } from '@kit.AbilityKit'
import { TitleBar } from '../base/TitleBar'
import { LoadingOverlay } from '../base/PageStates'

const TAG = 'DeviceAuth'

/** 插件信息 */
interface PluginItem {
  id: string
  name: string
  icon: string
  type: string
}

/** 插件列表响应 data */
interface PluginListData {
  plugins: PluginItem[]
}

@Component
export struct DeviceAuth {
  @State loading: boolean = false
  @State authenticated: boolean = false
  @State showPluginSheet: boolean = false
  @State pluginList: PluginItem[] = []
  private client = HttpClientHolder.getInstance().getClient()
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  build() {
    NavDestination() {
      Stack() {
        Column() {
          TitleBar({ title: '设备认证', showBack: true, showLoading: this.loading })

        // 蓝色安全提示区域
        Column() {
          Text('安全提示')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
          Text('为了保障您的账户安全，请先完成设备认证。认证后该设备将成为您的可信设备。')
            .fontSize(13)
            .fontColor('#DDEEFF')
            .margin({ top: 8 })
            .lineHeight(20)
        }
        .width('100%')
        .padding(20)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#1E90FF', 0], ['#4169E1', 1]]
        })

        // 设备信息卡片
        Column() {
          Column() {
            Text('🛡')
              .fontSize(48)
            Text('设备认证')
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .margin({ top: 12 })
            Text('请确认以下设备信息')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 24, bottom: 16 })

          Divider()
            .color('#EEEEEE')
            .margin({ left: 16, right: 16 })

          Column({ space: 12 }) {
            this.DeviceInfoItem('设备名称', 'HarmonyOS Device')
            this.DeviceInfoItem('设备型号', 'Mate 60 Pro')
            this.DeviceInfoItem('系统版本', 'HarmonyOS 5.0')
            this.DeviceInfoItem('认证状态', this.authenticated ? '已认证' : '未认证')
          }
          .width('100%')
          .padding(20)
        }
        .width('100%')
        .margin({ top: 16, left: 16, right: 16 })
        .borderRadius(12)
        .backgroundColor(Color.White)
        .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })

        // 底部按钮
        Column() {
          Button(this.authenticated ? '已认证' : '确认认证')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(this.authenticated ? '#4CAF50' : '#FF6600')
            .borderRadius(8)
            .enabled(!this.loading && !this.authenticated)
            .onClick(() => this.fetchPlugins())
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 32 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 全屏加载遮罩
      if (this.loading) {
        LoadingOverlay({ message: '加载中...' })
      }

      // 插件选择底部弹窗
      if (this.showPluginSheet) {
        this.PluginSheetOverlay()
      }
    }
    .width('100%')
    .height('100%')
    }
    .hideTitleBar(true)
  }

  /** 插件选择底部弹窗 */
  @Builder
  PluginSheetOverlay() {
    Column() {
      // 半透明遮罩，点击关闭
      Column()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => { this.showPluginSheet = false })

      // 底部面板
      Column() {
        // 拖拽指示条
        Row() {
          Column()
            .width(40)
            .height(4)
            .borderRadius(2)
            .backgroundColor('#DDDDDD')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 10, bottom: 6 })

        // 标题行
        Row() {
          Text('选择认证方式')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Blank()
          Text('✕')
            .fontSize(20)
            .fontColor('#999999')
            .onClick(() => { this.showPluginSheet = false })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 12 })

        // 插件列表
        List({ space: 0 }) {
          ForEach(this.pluginList, (plugin: PluginItem) => {
            ListItem() {
              this.PluginItemRow(plugin)
            }
          }, (plugin: PluginItem) => plugin.id)
        }
        .width('100%')
        .constraintSize({ maxHeight: '50%' })

        // 取消按钮
        Button('取消')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .onClick(() => { this.showPluginSheet = false })

        Divider()
          .color('#F0F0F0')
      }
      .width('100%')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
  }

  /** 插件列表项 */
  @Builder
  PluginItemRow(plugin: PluginItem) {
    Column() {
      Row() {
        Text(plugin.icon)
          .fontSize(28)
        Column() {
          Text(plugin.name)
            .fontSize(15)
            .fontColor('#333333')
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text('>')
          .fontSize(14)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(() => this.onPluginSelected(plugin))

      Divider()
        .color('#F0F0F0')
        .margin({ left: 56, right: 16 })
    }
  }

  /** 设备信息行 */
  @Builder
  DeviceInfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#999999')
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
    }
    .width('100%')
  }

  /** 获取插件列表（Mock 数据） */
  private fetchPlugins(): void {
    this.loading = true
    setTimeout(() => {
      this.pluginList = [
        { id: '1', name: '人脸识别', icon: '👤', type: 'facerecognition' },
        { id: '2', name: '身份证读卡器', icon: '🪪', type: 'cardreader' },
        { id: '3', name: '指纹认证', icon: '☝️', type: 'fingerprint' },
        { id: '4', name: '签名板', icon: '✍️', type: 'signature' },
      ] as PluginItem[]
      this.showPluginSheet = true
      this.loading = false
    }, 500)
  }

  /** 选择插件回调 */
  private onPluginSelected(plugin: PluginItem): void {
    this.showPluginSheet = false
    // TODO: 根据 plugin.type 调用对应插件
  }
}
