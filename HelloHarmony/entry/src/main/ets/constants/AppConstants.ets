/**
 * 业务常量
 * 集中管理接口返回码、提示语等
 */

/** 接口返回码 */
export class ResultCode {
  static readonly SUCCESS: string = '000000'
  static readonly TOKEN_EXPIRED: string = '000001'
  static readonly PARAM_ERROR: string = '000002'
  static readonly AUTH_FAILED: string = '000003'
  static readonly SERVER_ERROR: string = '999999'
}

/** 提示语 */
export class Msg {
  static readonly SUCCESS: string = '交易成功'
  static readonly LOGIN_SUCCESS: string = '登录成功'
  static readonly TOKEN_EXPIRED: string = '登录已过期，请重新登录'
  static readonly NETWORK_ERROR: string = '网络异常，请稍后重试'
  static readonly PARAM_ERROR: string = '参数错误'
  static readonly SERVER_ERROR: string = '服务器开小差了，请稍后重试'
}
