/**
 * API 路径常量
 * 集中管理所有接口地址，调用方直接引用
 */

/** 用户相关 */
export class UserApi {
  static readonly LOGIN: string = '/api/v1/users/login'
  static readonly USER_LIST: string = '/api/v1/users/'
  static readonly USER_DETAIL: string = '/api/v1/users/{id}'
  static readonly LOGOUT: string = '/api/v1/users/logout'
}
