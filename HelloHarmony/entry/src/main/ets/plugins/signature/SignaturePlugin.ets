import { BasePlugin, PluginMode } from '../core/BasePlugin'
import { ComponentResult } from '../core/ComponentResult'

/**
 * 签名板组件
 *
 * 功能：
 * - 手写签名
 * - 签名图片导出（Base64）
 *
 * 调用方式：
 *   invoke('signature.sign', { title: '请签名', width: 500, height: 300 })
 */
export class SignaturePlugin extends BasePlugin {
  name: string = 'signature'
  mode: PluginMode = 'embedded'

  constructor() {
    super()
    this.registerMethod('sign', (params) => this.sign(params))
  }

  private async sign(params: Record<string, Object>): Promise<ComponentResult> {
    // TODO: 弹出签名弹窗，用户签名后导出 Base64
    return ComponentResult.error(-1, 'Not implemented')
  }
}
