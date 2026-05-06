/**
 * 传输层接口 — 不依赖任何 SDK
 * 换 SDK 时只需新增一个 Adapter 实现
 */

/** 文件上传表单项（替代 http.MultiFormData） */
export interface FormDataItem {
  name: string
  contentType: string
  remoteFileName?: string
  data: string | ArrayBuffer
}

/** Adapter 层的请求对象 */
export interface AdapterRequest {
  method: string
  url: string
  headers: Record<string, string>
  body: Object | null
  contentType: string
  connectTimeout: number
  readTimeout: number
  multiFormDataList: FormDataItem[]
}

/** Adapter 层的响应对象 */
export interface AdapterResponse {
  httpStatus: number
  headers: Record<string, string>
  body: Object | null
}

/** 传输层接口 */
export interface IHttpAdapter {
  sendRequest(request: AdapterRequest): Promise<AdapterResponse>
}
