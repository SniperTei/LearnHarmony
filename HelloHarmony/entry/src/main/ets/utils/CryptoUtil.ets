import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { buffer, util } from '@kit.ArkTS'
import { PureCrypto } from './PureCrypto'

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

  private static uint8ArrayToStr(arr: Uint8Array): string {
    return buffer.from(arr.buffer).toString('utf-8')
  }

  private static uint8ArrayToHex(arr: Uint8Array): string {
    let hex = ''
    for (let i = 0; i < arr.length; i++) {
      hex += arr[i].toString(16).padStart(2, '0')
    }
    return hex
  }

  // ─── 哈希（系统 API，异步）──────────────────

  /** MD5 哈希，返回 32 位小写十六进制字符串 */
  static async md5(input: string): Promise<string> {
    const md = cryptoFramework.createMd('MD5')
    await md.update({ data: CryptoUtil.strToUint8Array(input) })
    const result = await md.digest()
    return CryptoUtil.uint8ArrayToHex(result.data)
  }

  /** SHA-256 哈希，返回 64 位小写十六进制字符串 */
  static async sha256(input: string): Promise<string> {
    const md = cryptoFramework.createMd('SHA256')
    await md.update({ data: CryptoUtil.strToUint8Array(input) })
    const result = await md.digest()
    return CryptoUtil.uint8ArrayToHex(result.data)
  }

  // ─── HMAC（纯实现，同步，支持任意长度密钥）───

  /** HMAC-SHA256，返回十六进制字符串 */
  static hmacSha256(input: string, key: string): string {
    const result = PureCrypto.hmacSha256Bytes(CryptoUtil.strToUint8Array(key), CryptoUtil.strToUint8Array(input))
    return CryptoUtil.uint8ArrayToHex(result)
  }

  /** HMAC-SHA512，返回十六进制字符串 */
  static hmacSha512(input: string, key: string): string {
    const result = PureCrypto.hmacSha512Bytes(CryptoUtil.strToUint8Array(key), CryptoUtil.strToUint8Array(input))
    return CryptoUtil.uint8ArrayToHex(result)
  }

  /** HMAC-SHA512，返回 Base64 字符串（匹配 Android HmacSHA512 输出） */
  static hmacSha512Base64(input: string, key: string): string {
    const result = PureCrypto.hmacSha512Bytes(CryptoUtil.strToUint8Array(key), CryptoUtil.strToUint8Array(input))
    const helper = new util.Base64Helper()
    return helper.encodeToStringSync(result)
  }

  // ─── Base64 ────────────────────────────────

  /** Base64 编码字符串 → 字符串 */
  static base64Encode(input: string): string {
    const helper = new util.Base64Helper()
    return helper.encodeToStringSync(CryptoUtil.strToUint8Array(input))
  }

  /** Base64 解码字符串 → 字符串 */
  static base64Decode(input: string): string {
    const helper = new util.Base64Helper()
    const bytes = helper.decodeSync(input)
    return CryptoUtil.uint8ArrayToStr(bytes)
  }
}
