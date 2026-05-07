import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

const STORE_NAME = 'hello_harmony_store'

/** 存储键名常量 */
export class StorageKey {
  static readonly TOKEN: string = 'token'
  static readonly LOGIN_DATA: string = 'login_data'
  static readonly USER_INFO: string = 'user_info'
  static readonly ENV_NAME: string = 'env_name'
  static readonly ENV_BASE_URL: string = 'env_base_url'
}

/**
 * SharedPreferences 封装
 * 需在 EntryAbility 中调用 init(context) 初始化
 */
export class StorageUtil {
  private static store: preferences.Preferences | null = null

  /** 初始化，在 Ability.onCreate 中调用 */
  static async init(context: Context): Promise<void> {
    StorageUtil.store = await preferences.getPreferences(context, STORE_NAME)
  }

  private static getStore(): preferences.Preferences {
    if (!StorageUtil.store) {
      throw new Error('StorageUtil 未初始化，请先调用 init(context)')
    }
    return StorageUtil.store
  }

  // ─── String ─────────────────────────────────

  static async putString(key: string, value: string): Promise<void> {
    const store = StorageUtil.getStore()
    await store.put(key, value)
    await store.flush()
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    const val = await StorageUtil.getStore().get(key, defaultValue)
    return val as string
  }

  // ─── Number ─────────────────────────────────

  static async putNumber(key: string, value: number): Promise<void> {
    const store = StorageUtil.getStore()
    await store.put(key, value)
    await store.flush()
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    const val = await StorageUtil.getStore().get(key, defaultValue)
    return val as number
  }

  // ─── Boolean ────────────────────────────────

  static async putBoolean(key: string, value: boolean): Promise<void> {
    const store = StorageUtil.getStore()
    await store.put(key, value)
    await store.flush()
  }

  static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    const val = await StorageUtil.getStore().get(key, defaultValue)
    return val as boolean
  }

  // ─── Object（JSON 序列化）────────────────────

  static async putObject<T extends Object>(key: string, value: T): Promise<void> {
    await StorageUtil.putString(key, JSON.stringify(value))
  }

  static async getObject<T extends Object>(key: string, defaultValue: T): Promise<T> {
    const json = await StorageUtil.getString(key)
    if (json === '') {
      return defaultValue
    }
    return JSON.parse(json) as T
  }

  // ─── 删除 & 清空 ────────────────────────────

  static async remove(key: string): Promise<void> {
    const store = StorageUtil.getStore()
    await store.delete(key)
    await store.flush()
  }

  static async clear(): Promise<void> {
    const store = StorageUtil.getStore()
    await store.clear()
    await store.flush()
  }

  // ─── 快捷方法：Token ────────────────────────

  static async saveToken(token: string): Promise<void> {
    await StorageUtil.putString(StorageKey.TOKEN, token)
  }

  static async getToken(): Promise<string> {
    return await StorageUtil.getString(StorageKey.TOKEN)
  }

  static async removeToken(): Promise<void> {
    await StorageUtil.remove(StorageKey.TOKEN)
  }
}
