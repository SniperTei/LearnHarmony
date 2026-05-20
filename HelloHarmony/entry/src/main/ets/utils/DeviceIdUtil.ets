import { asset } from '@kit.AssetStoreKit'
import { util } from '@kit.ArkTS'
import { LogUtil } from './LogUtil'

const TAG = 'DeviceIdUtil'
const ALIAS = 'app_device_unique_id'

export class DeviceIdUtil {
  private static cachedId: string = ''

  /**
   * 获取设备唯一 ID（首次自动生成并存储）
   */
  static async getDeviceId(): Promise<string> {
    if (DeviceIdUtil.cachedId) {
      return DeviceIdUtil.cachedId
    }

    // 1. 尝试从 Asset Store 读取
    try {
      const query: asset.AssetMap = new Map()
      query.set(asset.Tag.ALIAS, DeviceIdUtil.strToBytes(ALIAS))
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL as Object as Uint8Array)
      const results = asset.querySync(query)
      if (results.length > 0) {
        const first = results[0]
        const secret = first.get(asset.Tag.SECRET) as Uint8Array
        const id = DeviceIdUtil.bytesToStr(secret)
        if (id.length > 0) {
          DeviceIdUtil.cachedId = id
          LogUtil.info(TAG, `读取到 deviceId: ${id}`)
          return DeviceIdUtil.cachedId
        }
        asset.removeSync(query)
      }
    } catch (e) {
      LogUtil.info(TAG, 'Asset Store 中无记录，将生成新 ID')
    }

    // 2. 生成新 UUID 并存储
    const uuid = DeviceIdUtil.generateUUID()
    try {
      const attrs: asset.AssetMap = new Map()
      attrs.set(asset.Tag.ALIAS, DeviceIdUtil.strToBytes(ALIAS))
      attrs.set(asset.Tag.SECRET, DeviceIdUtil.strToBytes(uuid))
      attrs.set(asset.Tag.IS_PERSISTENT, true)
      asset.addSync(attrs)
      DeviceIdUtil.cachedId = uuid
      LogUtil.info(TAG, `生成并存储新 deviceId: ${uuid}`)
    } catch (e) {
      DeviceIdUtil.cachedId = uuid
      LogUtil.error(TAG, `Asset Store 存储失败: ${(e as Error).message}`)
    }

    return DeviceIdUtil.cachedId
  }

  /** 生成 16 位随机 ID */
  private static generateUUID(): string {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz'
    const charsArr = Array.from(chars)
    const id: string[] = []
    for (let i = 0; i < 16; i++) {
      const idx = Math.floor(Math.random() * charsArr.length)
      id.push(charsArr[idx])
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
