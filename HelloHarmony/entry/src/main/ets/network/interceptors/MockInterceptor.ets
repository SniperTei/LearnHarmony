import { hilog } from '@kit.PerformanceAnalysisKit'
import { RequestInterceptor } from './RequestInterceptor'
import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'

const TAG = 'MockInterceptor'

/**
 * Mock 拦截器
 * 开发调试用，匹配 URL 模式返回预设数据
 *
 * 用法：
 *   const mock = new MockInterceptor()
 *   mock.mock('GET', '/api/user', { name: 'test' })
 *   mock.mock('POST', '/api/login', { token: 'mock_token' })
 */
export class MockInterceptor implements RequestInterceptor {
  private mocks: Map<string, Object> = new Map()

  /** 注册 Mock 规则：method:url => response data */
  mock(method: string, url: string, responseData: Object): MockInterceptor {
    const key = `${method.toUpperCase()}:${url}`
    this.mocks.set(key, responseData)
    return this
  }

  /** 移除 Mock 规则 */
  removeMock(method: string, url: string): void {
    const key = `${method.toUpperCase()}:${url}`
    this.mocks.delete(key)
  }

  /** 清除所有 Mock */
  clearAll(): void {
    this.mocks.clear()
  }

  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    const methodStr = request.method.toString().toUpperCase()
    // 精确匹配
    const exactKey = `${methodStr}:${request.url}`
    if (this.mocks.has(exactKey)) {
      hilog.info(0, TAG, `Mock hit: ${exactKey}`)
      request.enableMock = true
      request.mockResponse = this.mocks.get(exactKey) ?? null
      return request
    }

    // 前缀匹配
    for (const key of this.mocks.keys()) {
      if (request.url.startsWith(key.substring(key.indexOf(':') + 1))) {
        hilog.info(0, TAG, `Mock prefix hit: ${key}`)
        request.enableMock = true
        request.mockResponse = this.mocks.get(key) ?? null
        return request
      }
    }

    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    return response
  }
}
