import { router } from '@kit.ArkUI'
import { ComponentResult } from './ComponentResult'

/**
 * 插件页面支持工具类
 *
 * ArkUI struct 不支持继承，因此用静态方法提供：
 * - Plugin 端：open() 打开页面并等待结果
 * - Page 端：getParam() 获取参数，finishSuccess/finishError 返回结果并关闭页面
 */
export class PluginPageSupport {
  private static resolver: ((result: ComponentResult) => void) | null = null
  private static storedParams: Record<string, Object> = {}
  private static routerInstance: router.Router | null = null

  /** 初始化，由页面组件在 aboutToAppear 中调用 */
  static init(routerInstance: router.Router): void {
    PluginPageSupport.routerInstance = routerInstance
  }

  private static getRouter(): router.Router {
    if (!PluginPageSupport.routerInstance) {
      throw new Error('PluginPageSupport 未初始化，请先调用 init(router)')
    }
    return PluginPageSupport.routerInstance
  }

  // === Plugin 端 ===

  /**
   * 打开插件页面，等待返回结果
   * @param url - 页面路径，如 'plugins/camera/CameraPage'
   * @param params - 传递给页面的参数
   * @returns 页面关闭后返回的 ComponentResult
   */
  static open(url: string, params?: Record<string, Object>): Promise<ComponentResult> {
    return new Promise<ComponentResult>((resolve) => {
      PluginPageSupport.resolver = resolve
      PluginPageSupport.storedParams = params ?? {}
      PluginPageSupport.getRouter().pushUrl({ url: `pages/${url}` })
    })
  }

  // === Page 端 ===

  /** 获取所有参数 */
  static getParams(): Record<string, Object> {
    return PluginPageSupport.storedParams
  }

  /** 获取单个参数（带默认值） */
  static getParam<T extends Object>(key: string, defaultValue: T): T {
    const value = PluginPageSupport.storedParams[key]
    if (value !== undefined && value !== null) {
      return value as T
    }
    return defaultValue
  }

  /** 成功返回并关闭页面 */
  static finishSuccess(data: Record<string, Object> | null = null, message: string = 'success'): void {
    PluginPageSupport.finish(ComponentResult.success(data, message))
  }

  /** 失败返回并关闭页面 */
  static finishError(code: number, message: string): void {
    PluginPageSupport.finish(ComponentResult.error(code, message))
  }

  /** 自定义返回并关闭页面 */
  static finish(result: ComponentResult): void {
    const resolver = PluginPageSupport.resolver
    PluginPageSupport.resolver = null
    if (resolver) {
      resolver(result)
    }
    PluginPageSupport.getRouter().back()
  }
}
