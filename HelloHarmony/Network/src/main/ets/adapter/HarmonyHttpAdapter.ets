/**
 * 基于 @kit.NetworkKit 的 Adapter 实现
 * 唯一依赖 HarmonyOS HTTP SDK 的地方
 */

import { http } from '@kit.NetworkKit'
import { IHttpAdapter, AdapterRequest, AdapterResponse } from './IHttpAdapter'

export class HarmonyHttpAdapter implements IHttpAdapter {
  async sendRequest(request: AdapterRequest): Promise<AdapterResponse> {
    const httpRequest = http.createHttp()
    try {
      const options = this.toSystemOptions(request)
      const response = await httpRequest.request(request.url, options)
      return this.toAdapterResponse(response)
    } finally {
      httpRequest.destroy()
    }
  }

  /** AdapterRequest → http.HttpRequestOptions */
  private toSystemOptions(request: AdapterRequest): http.HttpRequestOptions {
    const options: http.HttpRequestOptions = {
      method: this.toSystemMethod(request.method),
      header: request.headers,
      connectTimeout: request.connectTimeout,
      readTimeout: request.readTimeout,
      expectDataType: http.HttpDataType.OBJECT,
    }

    if (request.multiFormDataList.length > 0) {
      options.multiFormDataList = request.multiFormDataList.map(item => ({
        name: item.name,
        contentType: item.contentType,
        remoteFileName: item.remoteFileName ?? '',
        data: item.data,
      }) as http.MultiFormData)
    } else if (request.body !== null) {
      options.extraData = request.body
    }

    return options
  }

  /** 字符串方法名 → http.RequestMethod */
  private toSystemMethod(method: string): http.RequestMethod {
    const map: Record<string, http.RequestMethod> = {
      'GET': http.RequestMethod.GET,
      'POST': http.RequestMethod.POST,
      'PUT': http.RequestMethod.PUT,
      'DELETE': http.RequestMethod.DELETE,
    }
    return map[method] ?? http.RequestMethod.GET
  }

  /** http.HttpResponse → AdapterResponse */
  private toAdapterResponse(response: http.HttpResponse): AdapterResponse {
    const headers: Record<string, string> = {}
    if (response.header) {
      const headerObj = response.header as Record<string, string>
      for (const key of Object.keys(headerObj)) {
        headers[key] = String(headerObj[key])
      }
    }

    return {
      httpStatus: response.responseCode as number,
      headers: headers,
      body: response.result as Object ?? null,
    }
  }
}
