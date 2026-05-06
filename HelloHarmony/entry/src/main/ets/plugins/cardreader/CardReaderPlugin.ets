import { BasePlugin, PluginMode } from '../core/BasePlugin'
import { ComponentResult } from '../core/ComponentResult'

/**
 * 读卡读证组件
 *
 * 功能：
 * - 通过厂商 SDK 读取身份证/银行卡信息
 * - 多厂商支持，通过多态切换
 *
 * 调用方式：
 *   invoke('cardreader.readCard', { type: 'idcard' })
 *   invoke('cardreader.readCard', { type: 'bankcard' })
 */
export class CardReaderPlugin extends BasePlugin {
  name: string = 'cardreader'
  mode: PluginMode = 'embedded'

  constructor() {
    super()
    this.registerMethod('readCard', (params) => this.readCard(params))
  }

  private async readCard(params: Record<string, Object>): Promise<ComponentResult> {
    // TODO: 调用厂商 SDK
    return ComponentResult.error(-1, 'Not implemented')
  }
}
