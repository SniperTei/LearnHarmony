import { ComponentResult } from './ComponentResult'

/**
 * 插件调用模式
 * - page: 跳转原生页面（如拍照、人脸识别）
 * - embedded: 在 WebView 上层弹窗/浮层（如签名、密码键盘）
 */
export type PluginMode = 'page' | 'embedded'

type MethodHandler = (params: Record<string, Object>) => Promise<ComponentResult>

/**
 * 业务插件基类
 * 所有原生组件继承此类，通过 registerMethod 注册方法
 *
 * 子类只需：
 * 1. 声明 name 和 mode
 * 2. 在构造函数中调用 registerMethod() 注册方法
 */
export abstract class BasePlugin {
  /** 插件名称，如 'camera'、'cardreader' */
  abstract name: string

  /** 调用模式 */
  abstract mode: PluginMode

  private methodMap: Map<string, MethodHandler> = new Map()

  /**
   * 注册方法处理器
   * 子类在构造函数中调用此方法注册所有支持的方法
   */
  protected registerMethod(method: string, handler: MethodHandler): void {
    this.methodMap.set(method, handler)
  }

  /**
   * 处理 H5 调用 — 基类自动根据注册表分发
   */
  async handleMethod(method: string, params: Record<string, Object>): Promise<ComponentResult> {
    const handler = this.methodMap.get(method)
    if (handler) {
      return handler(params)
    }
    return ComponentResult.error(-1, `Unsupported method: ${method}`)
  }

  /**
   * 检查方法是否支持 — 基类自动根据注册表判断
   */
  supportsMethod(method: string): boolean {
    return this.methodMap.has(method)
  }
}
