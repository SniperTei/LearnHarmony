import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
import { IHttpAdapter, AdapterRequest } from './adapter/IHttpAdapter'

const PREF_NAME = 'http_token_pref'
const KEY_ACCESS_TOKEN = 'access_token'
const KEY_REFRESH_TOKEN = 'refresh_token'
const KEY_EXPIRE_TIME = 'expire_time'
const TOKEN_EXPIRE_BUFFER = 60 * 1000 // 提前 1 分钟判定过期

/**
 * Token 管理器
 * - 存储用 preferences（轻量 KV，跨重启持久化）
 * - 多请求同时 401，只发一次 refresh，其余等同一个 Promise
 */
export class TokenManager {
  private accessToken: string = ''
  private refreshToken: string = ''
  private expireTime: number = 0
  private isRefreshing: boolean = false
  private refreshPromise: Promise<boolean> | null = null
  private preferences: preferences.Preferences | null = null
  private refreshUrl: string = ''
  private adapter: IHttpAdapter | null = null
  private onTokenInvalidCallback: (() => void) | null = null

  /** 初始化（需要 Context 来访问 preferences） */
  async init(context: Context, refreshUrl: string, adapter: IHttpAdapter): Promise<void> {
    this.refreshUrl = refreshUrl
    this.adapter = adapter
    this.preferences = await preferences.getPreferences(context, PREF_NAME)
    this.accessToken = await this.preferences.get(KEY_ACCESS_TOKEN, '') as string
    this.refreshToken = await this.preferences.get(KEY_REFRESH_TOKEN, '') as string
    this.expireTime = await this.preferences.get(KEY_EXPIRE_TIME, 0) as number
  }

  /** 获取当前 accessToken */
  getAccessToken(): string {
    return this.accessToken
  }

  /** 设置 Token */
  async setTokens(accessToken: string, refreshToken: string, expiresIn: number): Promise<void> {
    this.accessToken = accessToken
    this.refreshToken = refreshToken
    this.expireTime = Date.now() + expiresIn * 1000

    if (this.preferences) {
      await this.preferences.put(KEY_ACCESS_TOKEN, accessToken)
      await this.preferences.put(KEY_REFRESH_TOKEN, refreshToken)
      await this.preferences.put(KEY_EXPIRE_TIME, this.expireTime)
      await this.preferences.flush()
    }
  }

  /** 判断 Token 是否过期 */
  isTokenExpired(): boolean {
    if (!this.accessToken) {
      return true
    }
    return Date.now() >= this.expireTime - TOKEN_EXPIRE_BUFFER
  }

  /** 刷新 Token（通过 adapter 发请求，不走拦截器） */
  async refresh(): Promise<boolean> {
    // 如果正在刷新，复用同一个 Promise
    if (this.isRefreshing && this.refreshPromise) {
      return this.refreshPromise
    }

    if (!this.refreshToken || !this.refreshUrl || !this.adapter) {
      return false
    }

    this.isRefreshing = true
    this.refreshPromise = this.doRefresh()

    try {
      return await this.refreshPromise
    } finally {
      this.isRefreshing = false
      this.refreshPromise = null
    }
  }

  /** 执行刷新请求 */
  private async doRefresh(): Promise<boolean> {
    try {
      const headers: Record<string, string> = {}
      headers['Content-Type'] = 'application/json'

      const body: Record<string, Object> = {}
      body['refreshToken'] = this.refreshToken

      const adapterRequest: AdapterRequest = {
        method: 'POST',
        url: this.refreshUrl,
        headers: headers,
        body: body,
        contentType: 'application/json',
        connectTimeout: 15000,
        readTimeout: 15000,
        multiFormDataList: [],
      }

      const response = await this.adapter!.sendRequest(adapterRequest)

      if (response.httpStatus === 200) {
        const result = response.body as Record<string, Object>
        if (result) {
          const newAccessToken = result['accessToken'] as string ?? ''
          const newRefreshToken = result['refreshToken'] as string ?? this.refreshToken
          const expiresIn = (result['expiresIn'] as number) ?? 7200

          if (newAccessToken) {
            await this.setTokens(newAccessToken, newRefreshToken, expiresIn)
            return true
          }
        }
      }

      // 刷新失败，通知应用层
      this.notifyTokenInvalid()
      return false
    } catch (e) {
      this.notifyTokenInvalid()
      return false
    }
  }

  /** 清除 Token */
  async clearTokens(): Promise<void> {
    this.accessToken = ''
    this.refreshToken = ''
    this.expireTime = 0

    if (this.preferences) {
      await this.preferences.delete(KEY_ACCESS_TOKEN)
      await this.preferences.delete(KEY_REFRESH_TOKEN)
      await this.preferences.delete(KEY_EXPIRE_TIME)
      await this.preferences.flush()
    }
  }

  /** 设置 Token 失效回调（跳登录页） */
  setOnTokenInvalid(callback: () => void): void {
    this.onTokenInvalidCallback = callback
  }

  /** 通知 Token 失效 */
  private notifyTokenInvalid(): void {
    if (this.onTokenInvalidCallback) {
      this.onTokenInvalidCallback()
    }
  }
}
