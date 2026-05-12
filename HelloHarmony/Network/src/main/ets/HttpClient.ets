import { HttpConfig } from './HttpConfig'
import { HttpRequest, RequestOptions, HttpClientContext } from './HttpRequest'
import { HttpResponse } from './HttpResponse'
import { Call } from './Call'
import { RequestInterceptor } from './interceptors/RequestInterceptor'
import { IHttpAdapter } from './adapter/IHttpAdapter'
import { HarmonyHttpAdapter } from './adapter/HarmonyHttpAdapter'

/**
 * HTTP 客户端 — Call 的工厂
 * 持有全局配置、适配器、拦截器
 */
export class HttpClient implements HttpClientContext {
  /** 全局默认 Adapter，启动时设置一次即可 */
  private static defaultAdapter: IHttpAdapter | null = null

  /** 设置全局默认 Adapter（不设则用 HarmonyHttpAdapter） */
  static setDefaultAdapter(adapter: IHttpAdapter): void {
    HttpClient.defaultAdapter = adapter
  }

  private config: HttpConfig
  private adapter: IHttpAdapter
  private interceptors: RequestInterceptor[] = []

  constructor(config: HttpConfig, adapter?: IHttpAdapter) {
    this.config = config
    this.adapter = adapter ?? HttpClient.defaultAdapter ?? new HarmonyHttpAdapter()
  }

  /** 创建请求（绑定了 this 的 config + adapter + interceptors） */
  newRequest(url: string, options?: RequestOptions): HttpRequest {
    return new HttpRequest(url, options, this)
  }

  /** 添加拦截器 */
  addInterceptor(interceptor: RequestInterceptor): void {
    this.interceptors.push(interceptor)
  }

  /** 获取全局配置 */
  getConfig(): HttpConfig {
    return this.config
  }

  /** 获取适配器 */
  getAdapter(): IHttpAdapter {
    return this.adapter
  }

  /** 获取拦截器列表 */
  getInterceptors(): RequestInterceptor[] {
    return this.interceptors
  }

  /**
   * 向后兼容：直接执行请求
   * 内部创建 Call 并 execute
   */
  async execute<T extends Object = Object>(request: HttpRequest): Promise<HttpResponse<T>> {
    // 如果 request 没有 context，临时绑定
    const call = new Call(request, this.config, this.adapter, this.interceptors)
    return call.execute<T>()
  }
}
