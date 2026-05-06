# Network 网络模块使用文档

## 概述

一套可独立复用的 HTTP 网络库，基于 **Adapter 模式** 解耦底层 SDK，通过 **Interceptor 链** 处理横切关注点。

**核心设计**：
- 换底层网络 SDK 只需新增一个 Adapter，上层代码零改动
- 所有请求/响应统一走拦截器链，可插拔扩展
- 响应格式对齐服务端 `{ code, statusCode, msg, data, timestamp }`

---

## 目录结构

```
network/
├── index.ets                              # 统一导出（barrel file）
├── HttpClient.ets                         # HTTP 客户端，请求工厂
├── HttpClientHolder.ets                   # 全局单例持有者
├── HttpConfig.ets                         # 全局配置
├── HttpRequest.ets                        # 请求对象（含 HttpMethod 枚举）
├── Call.ets                               # 请求执行器（拦截器链 + 重试 + 响应解析）
├── HttpResponse.ets                       # 响应对象
├── HttpError.ets                          # 错误码常量
├── TokenManager.ets                       # Token 管理器
├── adapter/
│   ├── IHttpAdapter.ets                   # 传输层接口 + AdapterRequest/AdapterResponse
│   ├── HarmonyHttpAdapter.ets             # 默认实现（@kit.NetworkKit）
│   └── MyHttpAdapter.ets                  # 自定义 Adapter 模板
└── interceptors/
    ├── RequestInterceptor.ets             # 拦截器接口
    ├── LogInterceptor.ets                 # 日志拦截器（自动脱敏）
    ├── CommonHeaderInterceptor.ets        # 公共 Header 拦截器（动态注入）
    ├── TokenInterceptor.ets              # Token 自动附加 + 过期刷新
    ├── SignInterceptor.ets               # 请求签名（HMAC-SHA256）
    ├── EncryptInterceptor.ets            # 加解密（AES-CBC）
    └── MockInterceptor.ets               # Mock 拦截器（开发调试）
```

---

## 快速开始

### 1. 初始化

在 App 启动或首页 `aboutToAppear` 中初始化一次：

```typescript
import { HttpConfig, HttpClientHolder, LogInterceptor, CommonHeaderInterceptor } from '../network'

// 创建配置
const config = new HttpConfig()
config.baseUrl = 'http://115.191.30.167:8041'

// 初始化单例（整个 App 共享）
HttpClientHolder.getInstance().init(config, [
  new CommonHeaderInterceptor(),
  new LogInterceptor(),
])
```

### 2. GET 请求

```typescript
import { HttpClientHolder, HttpMethod, HttpResponse } from '../network'

const client = HttpClientHolder.getInstance().getClient()

const params: Record<string, string> = {}
params['page'] = '1'
params['page_size'] = '10'

const response: HttpResponse<UserListData> = await client
  .newRequest('/api/v1/users/', {
    method: HttpMethod.GET,
    params: params,
  })
  .buildCall()
  .execute<UserListData>()

if (response.isSuccess() && response.data) {
  // 成功，response.data 就是 UserListData 类型
}
```

### 3. POST 请求

**统一用 `params`**，模块内部自动将 POST/PUT 的 `params` 转为 `body`：

```typescript
const params: Record<string, string> = {}
params['identifier'] = '13013001300'
params['password'] = 'test1234'

const response: HttpResponse<LoginData> = await client
  .newRequest('/api/v1/users/login', {
    method: HttpMethod.POST,
    params: params,
  })
  .buildCall()
  .execute<LoginData>()
```

> POST/PUT 时 `params` 自动赋给 `body`，GET/DELETE 时 `params` 拼在 URL 查询参数。
> 如需显式控制，仍可用 `body` 字段。

---

## 全局配置（HttpConfig）

```typescript
const config = new HttpConfig()
config.baseUrl = 'https://api.example.com'     // 服务器地址
config.headers['X-App-Version'] = '1.0.0'       // 公共请求头（固定值）
config.connectTimeout = 15000                    // 连接超时（ms）
config.readTimeout = 30000                       // 读取超时（ms）
config.retryCount = 2                            // 重试次数
config.retryDelay = 1000                         // 重试间隔（ms）
config.signSecret = 'xxx'                        // 请求签名密钥
config.encryptKey = 'xxx'                        // AES 加密密钥
config.tokenRefreshUrl = '/api/v1/token/refresh' // Token 刷新地址
```

**运行时修改**（比如切换环境）：

```typescript
HttpClientHolder.getInstance().getClient().getConfig().baseUrl = 'https://new-server.com'
```

---

## 响应处理（HttpResponse）

### 响应结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `string` | 业务码，`"000000"` 为成功 |
| `statusCode` | `number` | 服务端状态码 |
| `msg` | `string` | 提示信息 |
| `data` | `T \| null` | 业务数据（泛型） |
| `timestamp` | `string` | 服务端时间戳 |
| `httpStatus` | `number` | HTTP 状态码（传输层） |
| `headers` | `Record<string, string>` | 响应头 |
| `costTime` | `number` | 请求耗时（ms） |

### 判断成功

```typescript
if (response.isSuccess()) {
  // response.code === '000000'
}
```

### 定义响应数据类型

```typescript
interface LoginData {
  access_token: string
  token_type: string
  user: UserInfo
}

const response: HttpResponse<LoginData> = await client
  .newRequest(url, { method: HttpMethod.POST, params: params })
  .buildCall()
  .execute<LoginData>()

// response.data 就是 LoginData 类型
const token = response.data?.access_token
```

---

## 拦截器

拦截器按注册顺序**正序**处理请求、**逆序**处理响应。

### 内置拦截器

| 拦截器 | 用途 | 使用场景 |
|--------|------|----------|
| `CommonHeaderInterceptor` | 动态注入公共 headers | 每次请求需加时间戳、随机数等 |
| `LogInterceptor` | 日志记录（自动脱敏） | 开发调试，生产可移除 |
| `TokenInterceptor` | 自动附加 Token + 过期刷新 | 登录后的接口 |
| `SignInterceptor` | HMAC-SHA256 请求签名 | 需要防篡改的场景 |
| `EncryptInterceptor` | AES-CBC 加解密 | 请求体/响应体需加密 |
| `MockInterceptor` | 返回预设数据 | 前端开发阶段，后端未就绪 |

### 日志拦截器

```typescript
new LogInterceptor()  // 使用默认脱敏字段（Authorization, Cookie, password, token, secret）
```

日志输出示例：
```
--> GET /api/v1/users/
    Headers: {"Authorization":"***"}
    Params: {"page":"1","page_size":"10"}
    Body: null
<-- HTTP 200 code=000000 cost=234ms
    Msg: success
```

### 公共 Header 拦截器

动态注入 headers（每次请求前计算）：

```typescript
export class CommonHeaderInterceptor implements RequestInterceptor {
  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    request.headers['myNum'] = `${Math.floor(Math.random() * 10000)}_${Date.now()}`
    return request
  }
  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    return response
  }
}
```

### Mock 拦截器

```typescript
const mock = new MockInterceptor()
mock.mock('POST', '/api/v1/users/login', {
  code: '000000',
  statusCode: 200,
  msg: '登录成功',
  data: { access_token: 'mock_token', user: { id: '1', username: 'test' } },
  timestamp: '2026-05-06'
})

// 注册到 client
HttpClientHolder.getInstance().init(config, [mock, ...])
```

匹配规则：
- **精确匹配**：`POST:/api/v1/users/login`
- **前缀匹配**：注册 `GET:/api/v1/users`，请求 `/api/v1/users/` 也能命中

单请求 Mock（链式调用）：

```typescript
const response = await client
  .newRequest(url, { method: HttpMethod.POST })
  .enableMocking({ code: '000000', data: { token: 'test' } })
  .buildCall()
  .execute()
```

### Token 拦截器

```typescript
const tokenManager = new TokenManager()
await tokenManager.init(context, '/api/v1/token/refresh', adapter)
tokenManager.setOnTokenInvalid(() => { /* 跳转登录页 */ })

const tokenInterceptor = new TokenInterceptor(tokenManager)
client.addInterceptor(tokenInterceptor)
```

- 自动在请求头加 `Authorization: Bearer <token>`
- Token 过期自动刷新，多请求并发只刷新一次
- 刷新失败通知上层跳登录页

### 签名拦截器

```typescript
new SignInterceptor('your-hmac-secret')
```

自动在请求头加 `X-Sign`、`X-Timestamp`、`X-Nonce`。

### 加密拦截器

```typescript
new EncryptInterceptor('0102030405060708090a0b0c0d0e0f00', '0102030405060708')
```

- 请求体自动 AES-CBC 加密
- 加密请求头加 `X-Encrypted: 1`
- 响应体自动解密

### 自定义拦截器

实现 `RequestInterceptor` 接口：

```typescript
import { RequestInterceptor } from '../network'
import { HttpRequest } from '../network'
import { HttpResponse } from '../network'

export class MyInterceptor implements RequestInterceptor {
  async onRequest(request: HttpRequest): Promise<HttpRequest> {
    // 修改 request（加 header、改 body 等）
    return request
  }

  async onResponse(response: HttpResponse): Promise<HttpResponse> {
    // 处理 response（统一错误处理等）
    return response
  }
}
```

---

## 自定义 Adapter（换底层 SDK）

只需 3 步：

### 1. 实现 IHttpAdapter 接口

```typescript
import { IHttpAdapter, AdapterRequest, AdapterResponse } from './IHttpAdapter'

export class MyHttpAdapter implements IHttpAdapter {
  async sendRequest(request: AdapterRequest): Promise<AdapterResponse> {
    // 1. AdapterRequest → SDK 调用
    // 2. SDK 响应 → AdapterResponse
  }
}
```

### 2. AdapterRequest 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `method` | `string` | HTTP 方法 |
| `url` | `string` | 完整 URL（已拼接 baseUrl 和查询参数） |
| `headers` | `Record<string, string>` | 请求头（已合并公共 + 单次） |
| `body` | `Object \| null` | 请求体 |
| `contentType` | `string` | 内容类型 |
| `connectTimeout` | `number` | 连接超时 |
| `readTimeout` | `number` | 读取超时 |
| `multiFormDataList` | `FormDataItem[]` | 文件上传表单 |

### 3. AdapterResponse 字段说明

只需凑出 3 个字段：

```typescript
const response: AdapterResponse = {
  httpStatus: 200,                          // HTTP 状态码
  headers: { 'Content-Type': 'application/json' },  // 响应头
  body: { code: '000000', data: {...} },    // 服务端返回的原始 JSON
}
```

### 4. 使用自定义 Adapter

```typescript
// 方式 A：全局默认
HttpClient.setDefaultAdapter(new MyHttpAdapter())

// 方式 B：单个 client
const client = new HttpClient(config, new MyHttpAdapter())
```

---

## 链式调用

```typescript
const response = await client
  .newRequest('/api/v1/users/', { method: HttpMethod.GET })
  .setHeader('X-Custom', 'value')           // 追加请求头
  .setTimeout(5000, 10000)                    // 单请求超时
  .setTag('user_list')                       // 请求标签
  .enableMocking({ code: '000000', data: {} }) // 单请求 Mock
  .buildCall()
  .execute<UserListData>()
```

---

## 单文件上传

```typescript
import { FormDataItem } from '../network'

const formData: FormDataItem[] = [{
  name: 'avatar',
  contentType: 'image/jpeg',
  remoteFileName: 'photo.jpg',
  data: imageArrayBuffer,
}]

const response = await client
  .newRequest('/api/v1/upload', {
    method: HttpMethod.POST,
    multiFormDataList: formData,
  })
  .buildCall()
  .execute()
```

---

## 错误处理

```typescript
try {
  const response = await client.newRequest(url, options).buildCall().execute()
  if (response.isSuccess()) {
    // 业务成功
  } else {
    // 业务失败，response.msg 有提示信息
  }
} catch (e) {
  // 网络异常
}

// 错误码判断
import { HttpError, HttpErrorCode } from '../network'

HttpError.isNetworkError(response.code)   // 是否网络错误
HttpError.isTokenError(response.code)     // 是否 Token 错误
HttpError.isRetryable(response.code)      // 是否可重试
```

错误码定义：

| 错误码 | 值 | 说明 |
|--------|------|------|
| `NETWORK_ERROR` | -1001 | 网络错误 |
| `TIMEOUT_ERROR` | -1002 | 超时 |
| `SSL_ERROR` | -1003 | SSL 证书错误 |
| `TOKEN_EXPIRED` | -2001 | Token 过期 |
| `TOKEN_INVALID` | -2002 | Token 无效 |
| `SERVER_ERROR` | -3001 | 服务器错误 |

---

## 请求流程

```
调用方 client.newRequest(url, options)
  │
  ▼
HttpRequest（POST/PUT 时 params → body）
  │
  ▼
.buildCall()
  │
  ▼
Call.execute()
  ├─ 请求拦截器链（正序）
  │   CommonHeaderInterceptor → LogInterceptor → ...
  ├─ 合并公共 headers（config.headers < request.headers）
  ├─ 拼接完整 URL（baseUrl + path + query params）
  ├─ Adapter.sendRequest()（底层 SDK 调用）
  ├─ 带重试（失败自动重试 retryCount 次）
  ├─ 解析响应（对齐 { code, statusCode, msg, data, timestamp }）
  └─ 响应拦截器链（逆序）
      ... → LogInterceptor → CommonHeaderInterceptor
  │
  ▼
HttpResponse<T>（泛型响应，调用方拿到类型安全的 data）
```

---

## 依赖

网络模块仅依赖 HarmonyOS 官方库，无任何第三方依赖，可独立复用：

- `@kit.NetworkKit` — HTTP 请求（仅 HarmonyHttpAdapter 使用）
- `@kit.ArkData` — preferences 持久化（TokenManager）
- `@kit.CryptoArchitectureKit` — 加解密（EncryptInterceptor、SignInterceptor）
- `@kit.PerformanceAnalysisKit` — hilog 日志
- `@kit.ArkTS` — util（TextEncoder、Base64Helper）
