/**
 * Call — HTTP 请求执行器
 * 持有一次请求的全部上下文（request + config + adapter + interceptors）
 */

import { HttpConfig } from './HttpConfig'
import { HttpRequest } from './HttpRequest'
import { HttpResponse } from './HttpResponse'
import { HttpErrorCode } from './HttpError'
import { IHttpAdapter, AdapterRequest, AdapterResponse } from './adapter/IHttpAdapter'
import { RequestInterceptor } from './interceptors/RequestInterceptor'

export class Call {
  private request: HttpRequest
  private config: HttpConfig
  private adapter: IHttpAdapter
  private interceptors: RequestInterceptor[]

  constructor(request: HttpRequest, config: HttpConfig, adapter: IHttpAdapter,
    interceptors: RequestInterceptor[]) {
    this.request = request
    this.config = config
    this.adapter = adapter
    this.interceptors = interceptors
  }

  /** 执行请求，返回泛型响应 */
  async execute<T extends Object = Object>(): Promise<HttpResponse<T>> {
    const startTime = Date.now()

    let currentRequest = this.request

    // Mock 拦截
    if (currentRequest.enableMock && currentRequest.mockResponse) {
      const resp = HttpResponse.success<T>(200, currentRequest.mockResponse as T)
      resp.costTime = Date.now() - startTime
      return resp
    }

    // 执行请求拦截器链（正序）
    for (const interceptor of this.interceptors) {
      currentRequest = await interceptor.onRequest(currentRequest)
    }

    // 再次检查 mock（拦截器可能设置了 mock）
    if (currentRequest.enableMock && currentRequest.mockResponse) {
      const resp = HttpResponse.success<T>(200, currentRequest.mockResponse as T)
      resp.costTime = Date.now() - startTime
      return resp
    }

    // 拼接完整 URL
    const fullUrl = this.buildFullUrl(currentRequest)

    // 获取超时配置
    const connectTimeout = currentRequest.connectTimeout > 0 ?
      currentRequest.connectTimeout : this.config.connectTimeout
    const readTimeout = currentRequest.readTimeout > 0 ?
      currentRequest.readTimeout : this.config.readTimeout
    const retryCount = currentRequest.retryCount >= 0 ?
      currentRequest.retryCount : this.config.retryCount

    // 合并公共 headers：config 公共 < request 单次（单次优先）
    const mergedHeaders: Record<string, string> = {}
    const configHeaderKeys = Object.keys(this.config.headers)
    for (const key of configHeaderKeys) {
      mergedHeaders[key] = this.config.headers[key]
    }
    const reqHeaderKeys = Object.keys(currentRequest.headers)
    for (const key of reqHeaderKeys) {
      mergedHeaders[key] = currentRequest.headers[key]
    }

    // 构建 AdapterRequest
    const adapterRequest: AdapterRequest = {
      method: currentRequest.method,
      url: fullUrl,
      headers: mergedHeaders,
      body: currentRequest.body,
      contentType: currentRequest.contentType,
      connectTimeout: connectTimeout,
      readTimeout: readTimeout,
      multiFormDataList: currentRequest.multiFormDataList,
    }

    // 带重试的请求
    let response: HttpResponse<T> | null = null
    let lastError: Error | null = null

    for (let attempt = 0; attempt <= retryCount; attempt++) {
      try {
        const adapterResp = await this.adapter.sendRequest(adapterRequest)
        response = this.parseResponse<T>(adapterResp)
        break
      } catch (err) {
        lastError = err as Error
        if (attempt < retryCount) {
          await this.delay(this.config.retryDelay)
        }
      }
    }

    if (!response) {
      response = this.handleError<T>(lastError!)
    }

    response.costTime = Date.now() - startTime

    // 执行响应拦截器链（逆序）
    let baseResponse: HttpResponse = response as HttpResponse
    for (let i = this.interceptors.length - 1; i >= 0; i--) {
      baseResponse = await this.interceptors[i].onResponse(baseResponse)
    }
    response = baseResponse as HttpResponse<T>

    return response
  }

  /** 拼接完整 URL */
  private buildFullUrl(request: HttpRequest): string {
    let url = this.config.baseUrl + request.url
    const paramKeys = Object.keys(request.params)
    if (paramKeys.length > 0) {
      const query = paramKeys
        .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(request.params[key])}`)
        .join('&')
      url += (url.includes('?') ? '&' : '?') + query
    }
    return url
  }

  /** 解析 AdapterResponse → HttpResponse<T> */
  private parseResponse<T extends Object>(adapterResp: AdapterResponse): HttpResponse<T> {
    const httpStatus = adapterResp.httpStatus

    // HTTP 错误
    if (httpStatus >= 400) {
      return HttpResponse.error(String(httpStatus), httpStatus, this.getHttpErrorMessage(httpStatus))
    }

    // 解析业务响应（对齐服务端 { code, statusCode, msg, data, timestamp }）
    const responseBody = adapterResp.body as Record<string, Object> | null
    if (responseBody && typeof responseBody === 'object') {
      const code = (responseBody['code'] as string) ?? ''
      const statusCode = (responseBody['statusCode'] as number) ?? httpStatus
      const msg = (responseBody['msg'] as string) ?? ''
      const data = (responseBody['data'] as T) ?? null
      const timestamp = (responseBody['timestamp'] as string) ?? ''

      const resp = HttpResponse.success<T>(httpStatus, data, msg)
      resp.code = code
      resp.statusCode = statusCode
      resp.timestamp = timestamp
      resp.headers = adapterResp.headers
      return resp
    }

    // 非 JSON 响应
    const resp = HttpResponse.success<T>(httpStatus, adapterResp.body as T)
    resp.headers = adapterResp.headers
    return resp
  }

  /** 处理请求异常 */
  private handleError<T extends Object>(error: Error): HttpResponse<T> {
    const msg = error.message ?? 'Unknown error'
    if (msg.includes('timeout') || msg.includes('Timeout')) {
      return HttpResponse.error(String(HttpErrorCode.TIMEOUT_ERROR), 0, `请求超时: ${msg}`)
    }
    if (msg.includes('SSL') || msg.includes('certificate')) {
      return HttpResponse.error(String(HttpErrorCode.SSL_ERROR), 0, `SSL错误: ${msg}`)
    }
    return HttpResponse.error(String(HttpErrorCode.NETWORK_ERROR), 0, `网络错误: ${msg}`)
  }

  /** 获取 HTTP 错误信息 */
  private getHttpErrorMessage(status: number): string {
    const messages: Record<number, string> = {
      400: '请求参数错误',
      401: '未授权',
      403: '禁止访问',
      404: '资源不存在',
      405: '请求方法不允许',
      500: '服务器内部错误',
      502: '网关错误',
      503: '服务不可用',
    }
    return messages[status] ?? `HTTP错误 ${status}`
  }

  /** 延迟 */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
