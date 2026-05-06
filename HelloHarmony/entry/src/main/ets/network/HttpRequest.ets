import { FormDataItem } from './adapter/IHttpAdapter'
import { Call } from './Call'
import { HttpConfig } from './HttpConfig'
import { IHttpAdapter } from './adapter/IHttpAdapter'
import { RequestInterceptor } from './interceptors/RequestInterceptor'

/**
 * HTTP 方法枚举（不依赖 @kit.NetworkKit）
 */
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
}

/**
 * 请求选项
 */
export interface RequestOptions {
  method?: HttpMethod
  headers?: Record<string, string>
  params?: Record<string, string>
  body?: Object
  tag?: string
  connectTimeout?: number
  readTimeout?: number
  multiFormDataList?: FormDataItem[]
}

/**
 * HttpClient 上下文接口（避免循环导入）
 */
export interface HttpClientContext {
  getConfig(): HttpConfig
  getAdapter(): IHttpAdapter
  getInterceptors(): RequestInterceptor[]
}

/**
 * HTTP 请求对象
 * 构造时传入 url + options，通过 buildCall() 创建执行器
 */
export class HttpRequest {
  /** HTTP 方法 */
  method: HttpMethod = HttpMethod.GET
  /** 请求路径（相对 baseUrl） */
  url: string = ''
  /** 请求头 */
  headers: Record<string, string> = {}
  /** URL 查询参数 */
  params: Record<string, string> = {}
  /** 请求体 */
  body: Object | null = null
  /** 内容类型 */
  contentType: string = 'application/json'
  /** 请求标签（用于日志和取消） */
  tag: string = ''
  /** 文件上传表单数据 */
  multiFormDataList: FormDataItem[] = []
  /** 覆盖全局重试次数 */
  retryCount: number = -1
  /** 覆盖全局读取超时 */
  readTimeout: number = -1
  /** 覆盖全局连接超时 */
  connectTimeout: number = -1
  /** 单请求启用 Mock */
  enableMock: boolean = false
  /** Mock 响应数据 */
  mockResponse: Object | null = null

  /** 持有创建者 HttpClient 上下文 */
  private context: HttpClientContext | null = null

  constructor(url: string, options?: RequestOptions, context?: HttpClientContext) {
    this.url = url
    this.context = context ?? null

    if (options) {
      if (options.method !== undefined) {
        this.method = options.method
      }
      if (options.headers) {
        this.headers = options.headers
      }
      if (options.params) {
        // POST/PUT/DELETE → params 自动转 body；GET/DELETE → 保留为 URL 查询参数
        if (this.method === HttpMethod.POST || this.method === HttpMethod.PUT) {
          this.body = options.params
        } else {
          this.params = options.params as Record<string, string>
        }
      }
      if (options.body !== undefined) {
        this.body = options.body
      }
      if (options.tag !== undefined) {
        this.tag = options.tag
      }
      if (options.connectTimeout !== undefined) {
        this.connectTimeout = options.connectTimeout
      }
      if (options.readTimeout !== undefined) {
        this.readTimeout = options.readTimeout
      }
      if (options.multiFormDataList) {
        this.multiFormDataList = options.multiFormDataList
      }
    }
  }

  /** 创建 Call 执行器 */
  buildCall(): Call {
    if (!this.context) {
      throw new Error('HttpRequest 未绑定 HttpClient，请使用 HttpClient.newRequest() 创建请求')
    }
    return new Call(this, this.context.getConfig(), this.context.getAdapter(),
      this.context.getInterceptors())
  }

  // 链式调用
  setHeader(key: string, value: string): HttpRequest {
    this.headers[key] = value
    return this
  }

  setBody(body: Object): HttpRequest {
    this.body = body
    return this
  }

  setTag(tag: string): HttpRequest {
    this.tag = tag
    return this
  }

  setTimeout(connectTimeout: number, readTimeout: number): HttpRequest {
    this.connectTimeout = connectTimeout
    this.readTimeout = readTimeout
    return this
  }

  enableMocking(mockResponse: Object): HttpRequest {
    this.enableMock = true
    this.mockResponse = mockResponse
    return this
  }
}
