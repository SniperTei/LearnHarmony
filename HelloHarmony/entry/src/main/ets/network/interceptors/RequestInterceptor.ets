import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'

/**
 * 请求拦截器接口
 * 请求阶段正序执行，响应阶段逆序执行
 */
export interface RequestInterceptor {
  /** 请求拦截 */
  onRequest(request: HttpRequest): Promise<HttpRequest>

  /** 响应拦截 */
  onResponse(response: HttpResponse): Promise<HttpResponse>
}
