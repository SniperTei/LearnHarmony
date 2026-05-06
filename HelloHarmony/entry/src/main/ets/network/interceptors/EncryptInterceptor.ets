import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'
import { RequestInterceptor } from './RequestInterceptor'
import { HttpRequest } from '../HttpRequest'
import { HttpResponse } from '../HttpResponse'

const HEADER_ENCRYPTED = 'X-Encrypted'

/**
 * 加解密拦截器
 * 使用 AES-CBC 对请求体加密、响应体解密
 */
export class EncryptInterceptor implements RequestInterceptor {
  private key: string
  private iv: string

  constructor(key: string, iv: string = '0102030405060708') {
    this.key = key
    this.iv = iv
  }

  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    if (!request.body || !this.key) {
      return request
    }

    try {
      const plaintext = JSON.stringify(request.body)
      const encrypted = await this.aesEncrypt(plaintext)
      request.headers[HEADER_ENCRYPTED] = '1'
      request.headers['Content-Type'] = 'text/plain'
      const body: Record<string, Object> = {}
      body['data'] = encrypted
      request.body = body
    } catch (e) {
      // 加密失败，发送原始数据
    }

    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    if (!response.data || !this.key) {
      return response
    }

    // 检查是否为加密响应
    const encrypted = response.headers[HEADER_ENCRYPTED.toLowerCase()]
    if (encrypted !== '1') {
      return response
    }

    try {
      const dataObj = response.data as Record<string, Object>
      const encryptedData = dataObj['data'] as string
      if (encryptedData) {
        const decrypted = await this.aesDecrypt(encryptedData)
        response.data = JSON.parse(decrypted)
      }
    } catch (e) {
      // 解密失败，返回原始数据
    }

    return response
  }

  /** AES-CBC 加密 */
  private async aesEncrypt(plaintext: string): Promise<string> {
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128')
    const cipher = cryptoFramework.createCipher('AES128|CBC|PKCS7')

    const keyData = this.hexStringToUint8Array(this.key)
    const ivData = this.hexStringToUint8Array(this.iv)

    const keyBlob: cryptoFramework.DataBlob = { data: keyData }
    const symKey = await symKeyGenerator.convertKey(keyBlob)

    const ivBlob: cryptoFramework.DataBlob = { data: ivData }
    const ivParamsSpec: cryptoFramework.IvParamsSpec = { algName: 'IvParamsSpec', iv: ivBlob }
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, ivParamsSpec)

    const encoder = new util.TextEncoder()
    const input: cryptoFramework.DataBlob = { data: encoder.encodeInto(plaintext) }
    const output = await cipher.doFinal(input)

    // 转为 Base64
    const base64 = new util.Base64Helper()
    return base64.encodeToStringSync(output.data)
  }

  /** AES-CBC 解密 */
  private async aesDecrypt(ciphertext: string): Promise<string> {
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128')
    const cipher = cryptoFramework.createCipher('AES128|CBC|PKCS7')

    const keyData = this.hexStringToUint8Array(this.key)
    const ivData = this.hexStringToUint8Array(this.iv)

    const keyBlob: cryptoFramework.DataBlob = { data: keyData }
    const symKey = await symKeyGenerator.convertKey(keyBlob)

    const ivBlob: cryptoFramework.DataBlob = { data: ivData }
    const ivParamsSpec: cryptoFramework.IvParamsSpec = { algName: 'IvParamsSpec', iv: ivBlob }
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, ivParamsSpec)

    const base64 = new util.Base64Helper()
    const encryptedData = base64.decodeSync(ciphertext)

    const input: cryptoFramework.DataBlob = { data: encryptedData }
    const output = await cipher.doFinal(input)

    const decoder = new util.TextDecoder('utf-8')
    return decoder.decodeToString(output.data)
  }

  /** Hex 字符串转 Uint8Array */
  private hexStringToUint8Array(hex: string): Uint8Array {
    const length = hex.length / 2
    const array = new Uint8Array(length)
    for (let i = 0; i < length; i++) {
      array[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16)
    }
    return array
  }
}
