import { asset } from '@kit.AssetStoreKit'
import { util } from '@kit.ArkTS'
import { LogUtil } from './LogUtil'

const TAG = 'DeviceIdUtil'
const ALIAS = 'app_device_unique_id'

export class DeviceIdUtil {
  private static cachedId: string = ''

  /**
   * 获取设备唯一 ID（首次自动生成并存储）
   * app 卸载重装后返回相同的值
   */
  static async getDeviceId(): Promise<string> {
    if (DeviceIdUtil.cachedId) {
      return DeviceIdUtil.cachedId
    }

    // 1. 尝试从 Asset Store 读取
    try {
      const query = new Map<number, Uint8Array | boolean>()
      query.set(asset.Tag.ALIAS, DeviceIdUtil.strToBytes(ALIAS))
      const results = asset.query(query)
      if (results.length > 0) {
        const secret = results[0].get(asset.Tag.SECRET) as Uint8Array
        DeviceIdUtil.cachedId = DeviceIdUtil.bytesToStr(secret)
        LogUtil.info(TAG, `从 Asset Store 读取到 deviceId: ${DeviceIdUtil.cachedId}`)
        return DeviceIdUtil.cachedId
      }
    } catch (e) {
      LogUtil.info(TAG, 'Asset Store 中无记录，将生成新 ID')
    }

    // 2. 生成新 UUID 并存储
    const uuid = DeviceIdUtil.generateUUID()
    try {
      const attrs = new Map<number, Uint8Array | boolean>()
      attrs.set(asset.Tag.ALIAS, DeviceIdUtil.strToBytes(ALIAS))
      attrs.set(asset.Tag.SECRET, DeviceIdUtil.strToBytes(uuid))
      attrs.set(asset.Tag.IS_PERSISTENT, true)
      asset.add(attrs)
      DeviceIdUtil.cachedId = uuid
      LogUtil.info(TAG, `生成并存储新 deviceId: ${uuid}`)
    } catch (e) {
      // 存储失败仍返回 UUID（仅内存中有效）
      DeviceIdUtil.cachedId = uuid
      LogUtil.error(TAG, `Asset Store 存储失败: ${(e as Error).message}`)
    }

    return DeviceIdUtil.cachedId
  }

  /** 生成 16 位随机 ID */
  private static generateUUID(): string {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz'
    const id: string[] = []
    for (let i = 0; i < 16; i++) {
      const idx = Math.floor(Math.random() * chars.length)
      id.push(chars[idx])
    }
    return id.join('')
  }

  // ── 编码工具 ──

  private static strToBytes(str: string): Uint8Array {
    const encoder = new util.TextEncoder()
    return encoder.encodeInto(str)
  }

  private static bytesToStr(bytes: Uint8Array): string {
    const decoder = new util.TextDecoder('utf-8')
    return decoder.decodeToString(bytes)
  }
}
