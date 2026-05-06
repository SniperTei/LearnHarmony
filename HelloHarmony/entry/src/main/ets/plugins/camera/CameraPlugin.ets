import { BasePlugin, PluginMode } from '../core/BasePlugin'
import { ComponentResult } from '../core/ComponentResult'
import { PluginPageSupport } from '../core/PluginPageSupport'

/**
 * 拍照组件
 *
 * 功能：
 * - 自定义拍照页面
 * - 拍照后压缩图片
 * - 转换为 Base64
 * - 根据 H5 参数展示不同 UI（如身份证正面/反面）
 *
 * 调用方式：
 *   invoke('camera.takePhoto', { type: 'idcard_front', quality: 'high', maxWidth: 1920 })
 *   invoke('camera.takePhoto', { type: 'general', quality: 'medium' })
 */
export class CameraPlugin extends BasePlugin {
  name: string = 'camera'
  mode: PluginMode = 'page'

  constructor() {
    super()
    this.registerMethod('takePhoto', (params) => this.takePhoto(params))
  }

  private async takePhoto(params: Record<string, Object>): Promise<ComponentResult> {
    return PluginPageSupport.open('plugins/camera/CameraPage', params)
  }
}
