import { RequestInterceptor } from './RequestInterceptor'
import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'

/**
 * 公共 Header 拦截器
 * 每次请求前动态注入公共 headers
 */
export class CommonHeaderInterceptor implements RequestInterceptor {
  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    const random = Math.floor(Math.random() * 10000)
    const timestamp = Date.now()
    request.headers['myNum'] = `${random}_${timestamp}`
    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    return response
  }
}
