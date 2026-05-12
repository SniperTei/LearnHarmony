/** API 成功码（保持内部引用不变，值与 ResultCode.SUCCESS 一致） */
export const API_SUCCESS_CODE = '000000'

/**
 * API 响应基类
 * 对齐服务端统一响应格式：
 * { code: "000000", statusCode: 200, msg: "...", data: {...}, timestamp: "..." }
 */
export class ApiResponse<T extends Object = Object> {
  /** 业务码（字符串，如 "000000"） */
  code: string = ''
  /** 服务端返回的状态码 */
  statusCode: number = 200
  /** 消息 */
  msg: string = ''
  /** 业务数据 */
  data: T | null = null
  /** 服务端时间戳 */
  timestamp: string = ''
}

/**
 * HTTP 完整响应 = API 响应基类 + HTTP 传输层信息
 */
export class HttpResponse<T extends Object = Object> extends ApiResponse<T> {
  /** HTTP 状态码（传输层） */
  httpStatus: number = 200
  /** 响应头 */
  headers: Record<string, string> = {}
  /** 请求耗时（毫秒） */
  costTime: number = 0

  /** 是否业务成功 */
  isSuccess(): boolean {
    return this.code === API_SUCCESS_CODE
  }

  static success<T extends Object = Object>(httpStatus: number, data: T | null,
    msg: string = 'success'): HttpResponse<T> {
    const resp = new HttpResponse<T>()
    resp.code = API_SUCCESS_CODE
    resp.httpStatus = httpStatus
    resp.data = data
    resp.msg = msg
    return resp
  }

  static error<T extends Object = Object>(code: string, httpStatus: number, msg: string): HttpResponse<T> {
    const resp = new HttpResponse<T>()
    resp.code = code
    resp.httpStatus = httpStatus
    resp.msg = msg
    return resp
  }
}
