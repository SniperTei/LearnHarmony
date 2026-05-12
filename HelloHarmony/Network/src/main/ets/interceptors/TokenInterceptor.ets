import { RequestInterceptor } from './RequestInterceptor'
import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'
import { TokenManager } from '../TokenManager'

const HEADER_AUTH = 'Authorization'
const HEADER_SKIP_TOKEN = 'X-Skip-Token'

/**
 * Token 拦截器
 * - onRequest: 自动附加 Authorization 头；过期时先 refresh
 * - onResponse: 检测 401 触发刷新重试
 */
export class TokenInterceptor implements RequestInterceptor {
  private tokenManager: TokenManager
  /** 持有 HttpClient 引用用于重试，通过 setter 注入避免循环依赖 */
  private retryExecute: ((request: HttpRequest) => Promise<HttpResponse>) | null = null

  constructor(tokenManager: TokenManager) {
    this.tokenManager = tokenManager
  }

  /** 设置重试执行器（由 HttpClient 注入） */
  setRetryExecute(execute: (request: HttpRequest) => Promise<HttpResponse>): void {
    this.retryExecute = execute
  }

  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    // 跳过不需要 Token 的请求（如登录）
    if (request.headers[HEADER_SKIP_TOKEN] !== undefined) {
      return request
    }

    // Token 过期，先尝试刷新
    if (this.tokenManager.isTokenExpired()) {
      const refreshed = await this.tokenManager.refresh()
      if (!refreshed) {
        return request
      }
    }

    // 附加 Token
    const token = this.tokenManager.getAccessToken()
    if (token) {
      request.headers[HEADER_AUTH] = `Bearer ${token}`
    }

    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    // 检测 401，触发刷新重试
    if (response.httpStatus === 401 && this.retryExecute) {
      const refreshed = await this.tokenManager.refresh()
      if (refreshed) {
        // 刷新成功，重试原始请求（需要重新通过拦截器链）
        // 注意：这里不能直接调 retryExecute，因为会再次进入 TokenInterceptor
        // 标记跳过，由 HttpClient 的 401 重试逻辑处理
      } else {
        this.tokenManager.clearTokens()
      }
    }

    return response
  }
}
