/**
 * HTTP 错误码常量
 * 负数区间，避免和 HTTP 状态码、业务码冲突
 */
export enum HttpErrorCode {
  /** 网络错误（DNS、连接失败等） */
  NETWORK_ERROR = -1001,
  /** 超时 */
  TIMEOUT_ERROR = -1002,
  /** SSL 证书错误 */
  SSL_ERROR = -1003,
  /** Token 过期 */
  TOKEN_EXPIRED = -2001,
  /** Token 无效 */
  TOKEN_INVALID = -2002,
  /** 服务器错误 */
  SERVER_ERROR = -3001,
}

/**
 * HTTP 错误分类
 */
export namespace HttpError {
  /** 判断是否为网络层错误 */
  export function isNetworkError(code: number): boolean {
    return code >= -1099 && code <= -1001
  }

  /** 判断是否为 Token 相关错误 */
  export function isTokenError(code: number): boolean {
    return code === HttpErrorCode.TOKEN_EXPIRED || code === HttpErrorCode.TOKEN_INVALID
  }

  /** 判断是否可重试 */
  export function isRetryable(code: number): boolean {
    return code === HttpErrorCode.NETWORK_ERROR || code === HttpErrorCode.TIMEOUT_ERROR
  }
}
