import { BasePlugin, PluginMode } from '../core/BasePlugin'
import { ComponentResult } from '../core/ComponentResult'
import { PluginPageSupport } from '../core/PluginPageSupport'

/**
 * 人脸识别组件
 *
 * 功能：
 * - 活体检测
 * - 人脸比对
 *
 * 调用方式：
 *   invoke('face.verify', { mode: 'liveness' })
 */
export class FacePlugin extends BasePlugin {
  name: string = 'face'
  mode: PluginMode = 'page'

  constructor() {
    super()
    this.registerMethod('verify', (params) => this.verify(params))
  }

  private async verify(params: Record<string, Object>): Promise<ComponentResult> {
    return PluginPageSupport.open('plugins/facerecognition/FacePage', params)
  }
}
