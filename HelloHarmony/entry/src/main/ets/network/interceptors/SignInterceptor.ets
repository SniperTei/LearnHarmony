import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'
import { RequestInterceptor } from './RequestInterceptor'
import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'

const HEADER_SIGN = 'X-Sign'
const HEADER_TIMESTAMP = 'X-Timestamp'
const HEADER_NONCE = 'X-Nonce'

/**
 * 请求签名拦截器
 * 使用 HMAC-SHA256 + 时间戳 + 随机数进行请求签名
 * 将签名、时间戳、随机数附加到请求头
 */
export class SignInterceptor implements RequestInterceptor {
  private secret: string

  constructor(secret: string) {
    this.secret = secret
  }

  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    const timestamp = Date.now().toString()
    const nonce = this.generateNonce()
    const content = this.buildSignContent(request, timestamp, nonce)
    const sign = await this.hmacSha256(content, this.secret)

    request.headers[HEADER_SIGN] = sign
    request.headers[HEADER_TIMESTAMP] = timestamp
    request.headers[HEADER_NONCE] = nonce

    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    // 可选：验证服务端响应签名
    // 当前实现为透传
    return response
  }

  /** 构建签名内容 */
  private buildSignContent(request: HttpRequest, timestamp: string, nonce: string): string {
    let content = `${request.method}:${request.url}`
    content += `:${timestamp}:${nonce}`

    if (request.body) {
      content += `:${JSON.stringify(request.body)}`
    }

    return content
  }

  /** HMAC-SHA256 签名 */
  private async hmacSha256(content: string, secret: string): Promise<string> {
    try {
      const encoder = new util.TextEncoder()

      const md = cryptoFramework.createMac('SHA256')
      const keyBlob: cryptoFramework.DataBlob = { data: encoder.encodeInto(secret) }
      const keyGenerator = cryptoFramework.createSymKeyGenerator('HMAC|SHA256')
      const symKey = await keyGenerator.convertKey(keyBlob)
      await md.init(symKey)

      const dataBlob: cryptoFramework.DataBlob = { data: encoder.encodeInto(content) }
      await md.update(dataBlob)
      const result = await md.doFinal()

      return Array.from(result.data)
        .map(b => b.toString(16).padStart(2, '0'))
        .join('')
    } catch (e) {
      // 签名失败，返回空签名
      return ''
    }
  }

  /** 生成随机数 */
  private generateNonce(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    let result = ''
    for (let i = 0; i < 16; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }
}
