import { BasePlugin, PluginMode } from '../core/BasePlugin'
import { ComponentResult } from '../core/ComponentResult'

/**
 * 密码键盘组件
 *
 * 功能：
 * - 厂商 SDK 提供 UI，二次封装
 * - 弹窗式展示在 WebView 上层
 *
 * 调用方式：
 *   invoke('keyboard.show', { title: '请输入密码', maxLength: 6 })
 */
export class KeyboardPlugin extends BasePlugin {
  name: string = 'keyboard'
  mode: PluginMode = 'embedded'

  constructor() {
    super()
    this.registerMethod('show', (params) => this.show(params))
  }

  private async show(params: Record<string, Object>): Promise<ComponentResult> {
    // TODO: 调用厂商密码键盘 SDK，弹窗展示
    return ComponentResult.error(-1, 'Not implemented')
  }
}
