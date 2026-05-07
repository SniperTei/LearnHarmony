import { HttpResponse } from '../network'
import { hilog } from '@kit.PerformanceAnalysisKit'

/**
 * 网络请求辅助类
 * 封装通用的 try/catch/finally + loading 请求模式
 */
export interface RequestOptions<T extends Object> {
  /** 日志标签 */
  tag: string
  /** 请求执行函数 */
  request: () => Promise<HttpResponse<T>>
  /** 请求开始（通常设置 loading = true） */
  onStart?: () => void
  /** 请求成功回调 */
  onSuccess: (response: HttpResponse<T>) => void
  /** 请求异常回调 */
  onError?: (msg: string) => void
  /** 请求结束（通常设置 loading = false） */
  onFinish?: () => void
}

export class RequestHelper {
  static async execute<T extends Object>(options: RequestOptions<T>): Promise<void> {
    if (options.onStart) {
      options.onStart()
    }
    try {
      const response = await options.request()
      hilog.info(0, options.tag, `code=${response.code}, msg=${response.msg}`)
      options.onSuccess(response)
    } catch (e) {
      const msg = (e as Error).message
      hilog.error(0, options.tag, msg)
      if (options.onError) {
        options.onError(msg)
      }
    } finally {
      if (options.onFinish) {
        options.onFinish()
      }
    }
  }
}
