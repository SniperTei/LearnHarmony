import { HttpClient, HttpConfig, RequestInterceptor } from './index'

/**
 * HttpClient 单例持有者
 * 全局共享同一个 client 实例，任何页面都能用
 *
 * 用法：
 *   const client = HttpClientHolder.getInstance().getClient()
 *   const response = await client.newRequest('/api/...').buildCall().execute()
 */
export class HttpClientHolder {
  private static instance: HttpClientHolder | null = null
  private client: HttpClient | null = null

  private constructor() {}

  static getInstance(): HttpClientHolder {
    if (!HttpClientHolder.instance) {
      HttpClientHolder.instance = new HttpClientHolder()
    }
    return HttpClientHolder.instance
  }

  /** 初始化 client（App 启动时调一次） */
  init(config: HttpConfig, interceptors?: RequestInterceptor[]): void {
    this.client = new HttpClient(config)
    if (interceptors) {
      for (const interceptor of interceptors) {
        this.client.addInterceptor(interceptor)
      }
    }
  }

  /** 获取 client（未初始化会抛异常） */
  getClient(): HttpClient {
    if (!this.client) {
      throw new Error('HttpClient 未初始化，请先调用 init()')
    }
    return this.client
  }
}
