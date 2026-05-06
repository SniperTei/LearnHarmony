import { BasePlugin, PluginMode } from '../core/BasePlugin'
import { ComponentResult } from '../core/ComponentResult'

/**
 * 视频组件
 *
 * 功能：
 * - 视频播放
 * - 视频录制
 *
 * 调用方式：
 *   invoke('video.play', { url: '...' })
 *   invoke('video.record', { maxDuration: 30 })
 */
export class VideoPlugin extends BasePlugin {
  name: string = 'video'
  mode: PluginMode = 'page'

  constructor() {
    super()
    this.registerMethod('play', (params) => this.play(params))
    this.registerMethod('record', (params) => this.record(params))
  }

  private async play(params: Record<string, Object>): Promise<ComponentResult> {
    // TODO: 实现视频播放
    return ComponentResult.error(-1, 'Not implemented')
  }

  private async record(params: Record<string, Object>): Promise<ComponentResult> {
    // TODO: 实现视频录制
    return ComponentResult.error(-1, 'Not implemented')
  }
}
