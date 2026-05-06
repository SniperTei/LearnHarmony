/**
 * 自定义 Adapter 模板
 *
 * 只需关注 3 件事：
 * 1. import 你的 SDK
 * 2. AdapterRequest → SDK 请求（填 toSdkRequest）
 * 3. SDK 响应 → AdapterResponse（填 fromSdkResponse）
 */

// TODO: 第 1 步：导入你的 SDK
// import { SdkClient, SdkRequest, SdkResponse } from 'your-sdk'
import { IHttpAdapter, AdapterRequest, AdapterResponse } from './IHttpAdapter'

export class MyHttpAdapter implements IHttpAdapter {

  // TODO: 如果 SDK 需要初始化客户端，在构造函数中做
  // private sdkClient: SdkClient
  // constructor() {
  //   this.sdkClient = new SdkClient()
  // }

  async sendRequest(request: AdapterRequest): Promise<AdapterResponse> {
    // ──────────────────────────────────────────────
    // 第 2 步：AdapterRequest → SDK 请求
    // request 里已经拆好了所有字段，直接一一对应填入 SDK 的 API
    // ──────────────────────────────────────────────
    const sdkResponse = await this.callSdk(request)

    // ──────────────────────────────────────────────
    // 第 3 步：SDK 响应 → AdapterResponse
    // 只要凑出 httpStatus / headers / body 三个字段
    // ──────────────────────────────────────────────
    return this.fromSdkResponse(sdkResponse)
  }

  /**
   * 调用 SDK 发请求
   * 下面是伪代码，替换成你 SDK 的实际 API
   */
  private async callSdk(request: AdapterRequest): Promise<Object> {
    // 方式 A：SDK 也是 buildCall().execute() 风格
    // return await this.sdkClient
    //   .newRequest(request.url)
    //   .setMethod(request.method)
    //   .setHeaders(request.headers)
    //   .setBody(request.body)
    //   .setTimeout(request.connectTimeout, request.readTimeout)
    //   .buildCall()
    //   .execute()

    // 方式 B：SDK 是 request(url, options) 风格
    // return await this.sdkClient.request(request.url, {
    //   method: request.method,
    //   headers: request.headers,
    //   body: request.body,
    //   timeout: request.readTimeout,
    // })

    // 方式 C：SDK 是 fetch 风格
    // const response = await fetch(request.url, {
    //   method: request.method,
    //   headers: request.headers,
    //   body: request.body ? JSON.stringify(request.body) : undefined,
    // })
    // return response

    // 占位，编译需要
    const placeholder: Record<string, Object> = {}
    return placeholder
  }

  /**
   * SDK 响应 → AdapterResponse
   * 不管 SDK 返回什么类型，只要提取出 3 个字段：
   *   httpStatus  — HTTP 状态码（200、404...）
   *   headers     — 响应头
   *   body        — 响应体（JSON 对象，即服务端返回的原始数据）
   */
  private fromSdkResponse(sdkResponse: Object): AdapterResponse {
    // TODO: 根据 SDK 返回类型修改，下面是常见模式

    // const resp = sdkResponse as SdkResponse
    // const headers: Record<string, string> = {}
    // for (const key of Object.keys(resp.headers)) {
    //   headers[key] = String(resp.headers[key])
    // }
    // return {
    //   httpStatus: resp.status,
    //   headers: headers,
    //   body: resp.data,
    // }

    // 占位
    const emptyHeaders: Record<string, string> = {}
    const response: AdapterResponse = {
      httpStatus: 200,
      headers: emptyHeaders,
      body: null,
    }
    return response
  }
}
