import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { buffer, util } from '@kit.ArkTS'
import { PureCrypto } from './PureCrypto'
import { LogUtil } from './LogUtil'

const TAG = 'CryptoUtil'

/**
 * 加解密工具
 * 封装常用哈希、HMAC、Base64 等方法
 */
export class CryptoUtil {

  // ─── 内部转换 ──────────────────────────────

  private static strToUint8Array(str: string): Uint8Array {
    const buf = buffer.from(str, 'utf-8')
    return new Uint8Array(buf.buffer)
  }

  private static uint8ArrayToHex(arr: Uint8Array): string {
    let hex = ''
    for (let i = 0; i < arr.length; i++) {
      hex += arr[i].toString(16).padStart(2, '0')
    }
    return hex
  }

  // ─── 哈希（系统 API，异步）──────────────────

  /** MD5 哈希，返回 32 位小写十六进制字符串，失败返回空字符串 */
  static async md5(input: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('MD5')
      await md.update({ data: CryptoUtil.strToUint8Array(input) })
      const result = await md.digest()
      return CryptoUtil.uint8ArrayToHex(result.data)
    } catch (e) {
      LogUtil.error(TAG, `md5 failed: ${(e as Error).message}`)
      return ''
    }
  }

  /** SHA-256 哈希，返回 64 位小写十六进制字符串，失败返回空字符串 */
  static async sha256(input: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('SHA256')
      await md.update({ data: CryptoUtil.strToUint8Array(input) })
      const result = await md.digest()
      return CryptoUtil.uint8ArrayToHex(result.data)
    } catch (e) {
      LogUtil.error(TAG, `sha256 failed: ${(e as Error).message}`)
      return ''
    }
  }

  // ─── HMAC（纯实现，同步，支持任意长度密钥）───

  /** HMAC-SHA512，返回十六进制字符串，失败返回空字符串 */
  static hmacSha512(input: string, key: string): string {
    try {
      const result = PureCrypto.hmacSha512Bytes(CryptoUtil.strToUint8Array(key), CryptoUtil.strToUint8Array(input))
      return CryptoUtil.uint8ArrayToHex(result)
    } catch (e) {
      LogUtil.error(TAG, `hmacSha512 failed: ${(e as Error).message}`)
      return ''
    }
  }

  /** HMAC-SHA512，返回 Base64 字符串，失败返回空字符串 */
  static hmacSha512Base64(input: string, key: string): string {
    try {
      const result = PureCrypto.hmacSha512Bytes(CryptoUtil.strToUint8Array(key), CryptoUtil.strToUint8Array(input))
      const helper = new util.Base64Helper()
      return helper.encodeToStringSync(result)
    } catch (e) {
      LogUtil.error(TAG, `hmacSha512Base64 failed: ${(e as Error).message}`)
      return ''
    }
  }

  // ─── Base64 ────────────────────────────────

  /** Base64 编码，失败返回空字符串 */
  static base64Encode(input: string): string {
    try {
      const helper = new util.Base64Helper()
      return helper.encodeToStringSync(CryptoUtil.strToUint8Array(input))
    } catch (e) {
      LogUtil.error(TAG, `base64Encode failed: ${(e as Error).message}`)
      return ''
    }
  }

  /** Base64 解码，失败返回空字符串 */
  static base64Decode(input: string): string {
    try {
      const helper = new util.Base64Helper()
      const bytes = helper.decodeSync(input)
      return buffer.from(bytes.buffer).toString('utf-8')
    } catch (e) {
      LogUtil.error(TAG, `base64Decode failed: ${(e as Error).message}`)
      return ''
    }
  }
}
