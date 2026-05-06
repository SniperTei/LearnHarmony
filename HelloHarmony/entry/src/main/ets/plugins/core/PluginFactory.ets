import { BasePlugin } from './BasePlugin'
import { ComponentResult } from './ComponentResult'
import { HttpClient } from '../../network/HttpClient'

/**
 * 插件注册中心
 * 统一管理所有业务插件，提供按名查找
 *
 * TODO: 待混合开发框架接入后，替换为框架的注册机制
 */
export class PluginFactory {
  private static plugins: Map<string, BasePlugin> = new Map()
  private static httpClient: HttpClient | null = null

  /** 注册插件 */
  static register(plugin: BasePlugin): void {
    PluginFactory.plugins.set(plugin.name, plugin)
  }

  /** 获取插件 */
  static getPlugin(name: string): BasePlugin | undefined {
    return PluginFactory.plugins.get(name)
  }

  /** 处理 H5 调用: pluginName.methodName */
  static async invoke(pluginName: string, method: string, params: Record<string, Object>): Promise<ComponentResult> {
    const plugin = PluginFactory.plugins.get(pluginName)
    if (!plugin) {
      return ComponentResult.error(-1, `Plugin not found: ${pluginName}`)
    }
    return plugin.handleMethod(method, params)
  }

  /** 获取所有已注册插件名 */
  static getAllPluginNames(): string[] {
    return Array.from(PluginFactory.plugins.keys())
  }

  /** 初始化：注册所有插件 */
  static init(): void {
    // TODO: 在此注册所有插件
    // import 后调用 PluginFactory.register(new XxxPlugin())
  }

  /** 设置全局 HttpClient */
  static setHttpClient(client: HttpClient): void {
    PluginFactory.httpClient = client
  }

  /** 获取全局 HttpClient */
  static getHttpClient(): HttpClient {
    if (!PluginFactory.httpClient) {
      throw new Error('HttpClient 未初始化，请先调用 PluginFactory.setHttpClient()')
    }
    return PluginFactory.httpClient
  }
}
