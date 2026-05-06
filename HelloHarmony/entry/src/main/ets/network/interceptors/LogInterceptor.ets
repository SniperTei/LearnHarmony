import { hilog } from '@kit.PerformanceAnalysisKit'
import { RequestInterceptor } from './RequestInterceptor'
import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'
import { HttpConfig } from '../HttpConfig'

const TAG = 'HttpClient'

/**
 * 日志拦截器
 * 记录请求和响应信息，敏感字段脱敏
 */
export class LogInterceptor implements RequestInterceptor {
  private sensitiveHeaders: Set<string>
  private sensitiveParams: Set<string>

  constructor(config?: HttpConfig) {
    this.sensitiveHeaders = new Set(config?.sensitiveHeaders ?? ['Authorization', 'Cookie'])
    this.sensitiveParams = new Set(config?.sensitiveParams ?? ['password', 'token', 'secret'])
  }

  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    const maskedHeaders = this.maskHeaders(request.headers)
    const maskedParams = this.maskParams(request.params)
    const bodyStr = request.body ? this.maskBody(request.body) : 'null'

    hilog.info(0, TAG, `--> ${request.method} ${request.url}`)
    hilog.info(0, TAG, `    Headers: ${maskedHeaders}`)
    hilog.info(0, TAG, `    Params: ${maskedParams}`)
    hilog.info(0, TAG, `    Body: ${bodyStr}`)

    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    hilog.info(0, TAG, `<-- HTTP ${response.httpStatus} code=${response.code} cost=${response.costTime}ms`)
    hilog.info(0, TAG, `    Msg: ${response.msg}`)

    return response
  }

  /** 脱敏 Header */
  private maskHeaders(headers: Record<string, string>): string {
    const result: Record<string, string> = {}
    for (const key of Object.keys(headers)) {
      if (this.sensitiveHeaders.has(key.toLowerCase()) || this.sensitiveHeaders.has(key)) {
        result[key] = '***'
      } else {
        result[key] = headers[key]
      }
    }
    return JSON.stringify(result)
  }

  /** 脱敏查询参数 */
  private maskParams(params: Record<string, string>): string {
    const result: Record<string, string> = {}
    for (const key of Object.keys(params)) {
      if (this.sensitiveParams.has(key.toLowerCase()) || this.sensitiveParams.has(key)) {
        result[key] = '***'
      } else {
        result[key] = params[key]
      }
    }
    return JSON.stringify(result)
  }

  /** 脱敏请求体 */
  private maskBody(body: Object): string {
    try {
      const obj = body as Record<string, Object>
      const result: Record<string, Object> = {}
      for (const key of Object.keys(obj)) {
        if (this.sensitiveParams.has(key.toLowerCase()) || this.sensitiveParams.has(key)) {
          result[key] = '***'
        } else {
          result[key] = obj[key]
        }
      }
      return JSON.stringify(result)
    } catch (e) {
      return String(body)
    }
  }
}
