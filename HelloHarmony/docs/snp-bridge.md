# SNPBridge + SNPWebView H5-Native 桥接方案

## 概述

在 Common 模块里建一套 H5-Native 桥接基础设施，让 H5 能调用 native 的各种能力（密码键盘、人脸识别、签名、协议弹窗等自定义 UI），并能接收返回结果。

**核心设计**：
- **通信机制**：`javaScriptProxy` 注入对象，H5 调 `window.snpNative.call(...)`
- **返回值**：Callback 模式（H5 传 callbackId，native 通过 `runJavaScript` 推回结果）。支持多次回调（进度/连续操作）
- **架构模式**：依赖倒置——业务 module 依赖 Common 实现 `BridgeHandler`，entry 启动时 register。Common 不依赖业务 module
- **现有 Plugin 体系保留不动**：后续需要时写 Adapter 适配到 SNPBridge

---

## 一、依赖方向

```
Common (SNPRouter + SNPBridge + SNPWebView + BridgeHandler)
   ↑
   ├── entry (启动时 init + register)
   ├── PasswordModule → 依赖 Common，实现 BridgeHandler
   ├── FaceModule → 依赖 Common，实现 BridgeHandler
   └── SignatureModule → 依赖 Common，实现 BridgeHandler
```

业务 module 后续按需创建，本期只做 Common 基础设施。

---

## 二、清理：Hybrid 模块

- 删除 `/Hybrid` 整个目录（空壳，只有占位 MainPage）
- 修改根 `build-profile.json5`，从 `modules` 数组移除 Hybrid 项：

```json5
// 删除这一段：
{
  "name": "Hybrid",
  "srcPath": "./Hybrid",
}
```

---

## 三、Common 新增文件

### 目录结构

```
Common/src/main/ets/
├── bridge/
│   ├── BridgeResult.ets          # 标准响应格式
│   ├── BridgeCallbackPort.ets    # 回调出口接口（解耦 BridgeHandler 与 SNPBridge）
│   ├── BridgeHandler.ets         # 业务 handler 抽象基类
│   ├── SNPBridge.ets             # 单例桥接器
│   └── SystemHandler.ets         # 内置 demo handler（showToast / getDeviceInfo）
├── components/
│   └── SNPWebView.ets            # Web 组件封装
└── resources/rawfile/
    └── snp-bridge.js             # H5 端 SDK
```

### 1. `bridge/BridgeResult.ets`

标准响应格式。与 entry/plugins/core/ComponentResult 类似但独立，避免 Common 反向依赖 entry。

```ts
export class BridgeResult {
  code: number
  data: Record<string, Object> | null
  message: string

  constructor(code: number = 0, data: Record<string, Object> | null = null, message: string = 'success') {
    this.code = code
    this.data = data
    this.message = message
  }

  static success(data: Record<string, Object> | null = null, message: string = 'success'): BridgeResult {
    return new BridgeResult(0, data, message)
  }

  static error(code: number, message: string): BridgeResult {
    return new BridgeResult(code, null, message)
  }

  toJSON(): string {
    return JSON.stringify({ code: this.code, data: this.data, message: this.message })
  }
}
```

### 2. `bridge/BridgeCallbackPort.ets`

让 BridgeHandler 能回调 H5，但不直接依赖 SNPBridge 类。SNPBridge 实现这个接口，`attachBridge` 时传入。

```ts
import { BridgeResult } from './BridgeResult'

export interface BridgeCallbackPort {
  callback(callbackId: string, result: BridgeResult, finish?: boolean): void
}
```

> **为什么需要这个接口**：SNPBridge import BridgeHandler，BridgeHandler 又需要回调 H5（调 SNPBridge.callback）。如果 BridgeHandler 直接 import SNPBridge 类，会循环 import。方案 B 用接口彻底解耦——BridgeHandler 只依赖 `BridgeCallbackPort` 接口和 `BridgeResult`，SNPBridge 实现该接口。

### 3. `bridge/BridgeHandler.ets`

业务 handler 的抽象基类。子类实现 `onCall` 即可，需要回调结果时用 `resolve` / `reject` / `progress`。

```ts
import { BridgeResult } from './BridgeResult'
import { BridgeCallbackPort } from './BridgeCallbackPort'
import { UIContext } from '@kit.ArkUI'

export abstract class BridgeHandler {
  abstract name: string

  private callbackPort: BridgeCallbackPort | null = null
  private uiContext: UIContext | null = null

  /** SNPBridge.register 时自动调用 */
  attachBridge(port: BridgeCallbackPort, uiContext: UIContext | null): void {
    this.callbackPort = port
    this.uiContext = uiContext
  }

  /** 子类实现：处理 H5 调用。需要结果时调 resolve/reject/progress */
  abstract onCall(method: string, params: Record<string, Object>, callbackId: string): void

  /** 获取 UIContext（BridgeHandler 用它显示 UI） */
  protected getUIContext(): UIContext | null {
    return this.uiContext
  }

  /** 一次性成功返回（调用后 callbackId 在 H5 端释放） */
  protected resolve(callbackId: string, data: Record<string, Object> | null = null, message: string = 'success'): void {
    this.callbackPort?.callback(callbackId, BridgeResult.success(data, message), true)
  }

  /** 一次性错误返回 */
  protected reject(callbackId: string, code: number, message: string): void {
    this.callbackPort?.callback(callbackId, BridgeResult.error(code, message), true)
  }

  /** 中间进度回调（finish=false，H5 端不释放 callback） */
  protected progress(callbackId: string, data: Record<string, Object> | null = null): void {
    this.callbackPort?.callback(callbackId, BridgeResult.success(data, 'progress'), false)
  }
}
```

**子类示例**：

```ts
export class PasswordHandler extends BridgeHandler {
  name = 'password'

  onCall(method: string, params: Record<string, Object>, cbId: string): void {
    switch (method) {
      case 'showDialog':
        this.showPasswordDialog(params, cbId)
        break
      default:
        this.reject(cbId, 404, `Method [${method}] not supported`)
    }
  }

  private showPasswordDialog(params: Record<string, Object>, cbId: string): void {
    // 显示 UI...
    this.resolve(cbId, { password: 'xxx' })
  }
}
```

### 4. `bridge/SNPBridge.ets`

单例桥接器，仿 SNPRouter 范式。

**通信契约**：
- H5 调：`window.snpNative.call(plugin, method, paramsJson, callbackId)`
- Native 回：`window.snpBridge._onCallback(callbackId, resultJson, finish)`

```ts
import { hilog } from '@kit.PerformanceAnalysisKit'
import { webview } from '@kit.ArkWeb'
import { UIContext } from '@kit.ArkUI'
import { BridgeHandler } from './BridgeHandler'
import { BridgeResult } from './BridgeResult'
import { BridgeCallbackPort } from './BridgeCallbackPort'

const TAG = 'SNPBridge'

export class SNPBridge implements BridgeCallbackPort {
  private static instance: SNPBridge | null = null
  private handlers: Map<string, BridgeHandler> = new Map()
  private webviewController: webview.WebviewController | null = null
  private uiContext: UIContext | null = null

  private constructor() {}

  static getInstance(): SNPBridge {
    if (!SNPBridge.instance) {
      SNPBridge.instance = new SNPBridge()
    }
    return SNPBridge.instance
  }

  /** entry 启动时调用，注入 UI 上下文 */
  init(uiContext: UIContext): void {
    this.uiContext = uiContext
  }

  /** 由 SNPWebView 组件自动调用，绑定当前 webview controller */
  bindWebView(controller: webview.WebviewController): void {
    this.webviewController = controller
    hilog.info(0, TAG, 'WebviewController bound')
  }

  /** 解绑（SNPWebView 销毁时调用） */
  unbindWebView(): void {
    this.webviewController = null
  }

  /** 获取 UIContext（BridgeHandler 用它显示 UI） */
  getUIContext(): UIContext | null {
    return this.uiContext
  }

  /** 注册业务 handler */
  register(name: string, handler: BridgeHandler): void {
    if (this.handlers.has(name)) {
      hilog.warn(0, TAG, `Handler [${name}] 已存在，将被覆盖`)
    }
    handler.attachBridge(this, this.uiContext)
    this.handlers.set(name, handler)
    hilog.info(0, TAG, `Handler registered: ${name}`)
  }

  unregister(name: string): void {
    this.handlers.delete(name)
  }

  hasHandler(name: string): boolean {
    return this.handlers.has(name)
  }

  /**
   * H5 入口方法（通过 javaScriptProxy 暴露）
   * 注意：参数全部是基础类型，因为跨 JS/Native 边界
   */
  call(plugin: string, method: string, paramsJson: string, callbackId: string): void {
    hilog.info(0, TAG, `call: ${plugin}.${method} cb=${callbackId}`)

    const handler = this.handlers.get(plugin)
    if (!handler) {
      this.callback(callbackId, BridgeResult.error(404, `Handler [${plugin}] not found`))
      return
    }

    let params: Record<string, Object> = {}
    try {
      if (paramsJson) {
        params = JSON.parse(paramsJson) as Record<string, Object>
      }
    } catch (e) {
      this.callback(callbackId, BridgeResult.error(400, `params JSON 解析失败: ${(e as Error).message}`))
      return
    }

    try {
      handler.onCall(method, params, callbackId)
    } catch (e) {
      this.callback(callbackId, BridgeResult.error(500, `Handler 异常: ${(e as Error).message}`))
    }
  }

  /**
   * 推结果回 H5（BridgeHandler 通过基类 helper 调用）
   * 支持多次回调——只要 callbackId 还在 H5 端的 callback 表里
   */
  callback(callbackId: string, result: BridgeResult, finish: boolean = true): void {
    if (!this.webviewController) {
      hilog.warn(0, TAG, `callback 失败：webview 未绑定 (cb=${callbackId})`)
      return
    }
    const resultJson = JSON.stringify(result)
    const js = `window.snpBridge && window.snpBridge._onCallback && window.snpBridge._onCallback('${callbackId}', ${resultJson}, ${finish})`
    try {
      this.webviewController.runJavaScript(js)
    } catch (e) {
      hilog.error(0, TAG, `runJavaScript 失败: ${(e as Error).message}`)
    }
  }

  /**
   * Native 主动推事件给 H5（无需 H5 先调用）
   * 例如：native 检测到网络变化，通知 H5
   */
  sendEvent(eventName: string, data: Object): void {
    if (!this.webviewController) return
    const dataJson = JSON.stringify(data)
    const js = `window.snpBridge && window.snpBridge._onEvent && window.snpBridge._onEvent('${eventName}', ${dataJson})`
    try {
      this.webviewController.runJavaScript(js)
    } catch (e) {
      hilog.error(0, TAG, `sendEvent 失败: ${(e as Error).message}`)
    }
  }
}
```

**用法**：

```ts
// 1. entry 启动时初始化
SNPBridge.getInstance().init(this.getUIContext())

// 2. 注册业务 handler
SNPBridge.getInstance().register('password', new PasswordHandler())

// 3. SNPWebView 组件会自动绑定 webview controller

// H5 端调用：
window.snpBridge.call('password', 'showDialog', { title: '输入密码' }, (result) => {
  console.log('用户输入完成', result)
})
```

### 5. `bridge/SystemHandler.ets`

内置 demo handler，证明桥能跑通的最小示例。后续业务 module 照此模式。

```ts
import { BridgeHandler } from './BridgeHandler'

export class SystemHandler extends BridgeHandler {
  name = 'system'

  onCall(method: string, params: Record<string, Object>, callbackId: string): void {
    switch (method) {
      case 'showToast':
        this.showToast(params, callbackId)
        break
      case 'getDeviceInfo':
        this.resolve(callbackId, {
          brand: 'HarmonyOS',
          version: '6.1.0',
          timestamp: Date.now().toString(),
        })
        break
      default:
        this.reject(callbackId, 404, `Method [${method}] not supported`)
    }
  }

  private showToast(params: Record<string, Object>, callbackId: string): void {
    const msg = (params['msg'] as string) ?? ''
    const uiContext = this.getUIContext()
    if (!uiContext) {
      this.reject(callbackId, 500, 'UIContext 未初始化')
      return
    }
    uiContext.getPromptAction().showToast({ message: msg })
    this.resolve(callbackId, null, 'toast shown')
  }
}
```

### 6. `components/SNPWebView.ets`

WebView 组件封装。自动：① 注入 `javaScriptProxy` 暴露 `SNPBridge.call` 给 H5；② 绑定 controller 给 SNPBridge（用于 native 回调 H5）。

```ts
import { webview } from '@kit.ArkWeb'
import { SNPBridge } from '../bridge/SNPBridge'

@Component
export struct SNPWebView {
  @Prop src: string = ''
  @State controller: webview.WebviewController = new webview.WebviewController()

  build() {
    Web({ src: this.src, controller: this.controller })
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .fileAccess(true)
      .mixedMode(MixedMode.All)               // 允许 https 页面加载 http 资源
      .javaScriptProxy({
        object: SNPBridge.getInstance(),
        name: 'snpNative',                    // H5 通过 window.snpNative.call(...) 访问
        methodList: ['call'],                 // 只暴露 call 一个方法
        asyncMethodList: [],
        controller: this.controller,
      })
      .onControllerAttached(() => {
        // controller 此时绑定到 Web 组件，注册给 SNPBridge
        SNPBridge.getInstance().bindWebView(this.controller)
      })
      .onControllerDetached(() => {
        SNPBridge.getInstance().unbindWebView()
      })
  }
}
```

**用法**：

```ts
SNPWebView({ src: 'https://example.com' })
SNPWebView({ src: $rawfile('index.html') })  // 加载本地资源
```

> HarmonyOS `Web` 组件、`WebviewController`、`javaScriptProxy`、`onControllerAttached` 都是 ArkUI 内置 API，无需 oh-package 依赖（`@kit.ArkWeb` 是 SDK 自带）。

### 7. `resources/rawfile/snp-bridge.js`

H5 端 SDK。H5 页面引入这个 JS，提供友好的 `snpBridge.call(...)` API。

```js
/**
 * SNPBridge H5 端 SDK
 * 用法：
 *   <script src="snp-bridge.js"></script>
 *   snpBridge.call('system', 'showToast', { msg: 'hi' }, (result) => {
 *     console.log('result', result)
 *   })
 *
 *   // 多次回调场景（进度等）：
 *   snpBridge.call('upload', 'start', { file: 'xx' }, (result, finished) => {
 *     if (!finished) console.log('progress:', result)
 *     else console.log('done:', result)
 *   })
 */
;(function (global) {
  let cbIdSeed = 0
  const callbacks = {}

  global.snpBridge = {
    // 发起调用
    call: function (plugin, method, params, callback) {
      const cbId = 'cb_' + (++cbIdSeed)
      callbacks[cbId] = callback || null
      // 调原生注入的方法
      global.snpNative.call(plugin, method, JSON.stringify(params || {}), cbId)
    },

    // 订阅 native 主动推的事件（sendEvent）
    _listeners: {},
    on: function (eventName, handler) {
      if (!this._listeners[eventName]) this._listeners[eventName] = []
      this._listeners[eventName].push(handler)
    },

    // === 以下方法由 native 调用，业务代码不要直接调 ===
    _onCallback: function (cbId, result, finished) {
      const cb = callbacks[cbId]
      if (cb) {
        try {
          cb(result, finished)
        } catch (e) {
          console.error('[snpBridge] callback error', e)
        }
      }
      if (finished) delete callbacks[cbId]
    },
    _onEvent: function (eventName, data) {
      const handlers = this._listeners[eventName] || []
      handlers.forEach((h) => {
        try { h(data) } catch (e) { console.error('[snpBridge] event handler error', e) }
      })
    },
  }

  console.log('[snpBridge] SDK ready')
})(window)
```

---

## 四、修改文件

### 1. `Common/Index.ets`

```ts
export { MainPage } from './src/main/ets/components/MainPage'
export { SNPRouter } from './src/main/ets/router/SNPRouter'
export { SNPBridge } from './src/main/ets/bridge/SNPBridge'
export { BridgeHandler } from './src/main/ets/bridge/BridgeHandler'
export { BridgeResult } from './src/main/ets/bridge/BridgeResult'
export { SystemHandler } from './src/main/ets/bridge/SystemHandler'
export { SNPWebView } from './src/main/ets/components/SNPWebView'
```

### 2. 根 `build-profile.json5`

从 `modules` 数组移除 Hybrid（保留 entry/network/Common）。

### 3. （可选）`entry/oh-package.json5`

Common 已经是依赖了，不用改。Hybrid 删除后无影响。

---

## 五、端到端验证

### 1. 新建 `entry/src/main/resources/rawfile/bridge-test.html`

```html
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Bridge Test</title></head>
<body>
  <h3>SNPBridge Test</h3>
  <button onclick="testToast()">Show Toast</button>
  <button onclick="testDeviceInfo()">Get Device Info</button>
  <pre id="output"></pre>

  <script src="snp-bridge.js"></script>
  <script>
    function log(msg) {
      document.getElementById('output').textContent += msg + '\n'
    }

    function testToast() {
      snpBridge.call('system', 'showToast', { msg: 'Hello from H5!' }, (result, finished) => {
        log('Toast result: ' + JSON.stringify(result) + ' (finished=' + finished + ')')
      })
    }

    function testDeviceInfo() {
      snpBridge.call('system', 'getDeviceInfo', {}, (result, finished) => {
        log('Device info: ' + JSON.stringify(result))
      })
    }
  </script>
</body>
</html>
```

### 2. 新建 `entry/src/main/ets/pages/WebviewTest.ets`

```ts
import { SNPWebView } from 'common'

@Component
export struct WebviewTest {
  build() {
    NavDestination() {
      Column() {
        SNPWebView({ src: $rawfile('bridge-test.html') })
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
  }
}
```

### 3. Index.ets 加测试入口

在 Index 加按钮跳转到 WebviewTest，并在 `PageMap` 中加入映射。

### 4. entry 启动时注册 SystemHandler

在 `EntryAbility.onWindowStageCreate` 的 `loadContent` 回调里：

```ts
import { SNPBridge, SystemHandler } from 'common'

// windowStage.loadContent 回调里：
SNPBridge.getInstance().init(windowStage.getUIContext())
SNPBridge.getInstance().register('system', new SystemHandler())
```

> 若 `windowStage.getUIContext()` 在该阶段取不到，改在 Index 组件的 `aboutToAppear` 里 `SNPBridge.getInstance().init(this.getUIContext())`。

### 5. 期望行为

- 打开测试页 → 加载 HTML
- 点 "Show Toast" → HarmonyOS 系统 toast 弹出 "Hello from H5!"
- HTML 下方 `<pre>` 显示 "Toast result: {...} (finished=true)"
- 点 "Get Device Info" → 显示 `{brand: 'HarmonyOS', version: '6.1.0', ...}`

如果 toast 弹出且 result 回显，端到端桥就通了。

---

## 六、关键设计点

### 为什么 H5 端是两个对象 `snpNative` + `snpBridge`

- `window.snpNative` 是 `javaScriptProxy` 注入的**原始 native 对象**，只有 `call()` 一个方法，参数必须基础类型（string）
- `window.snpBridge` 是 H5 端 JS 封装的**友好 API**，提供 callback 注册表、事件订阅、JSON 序列化等
- 分层后：H5 业务代码用 `snpBridge`，底层通信走 `snpNative`

### 为什么 params 走 JSON string

跨 JS/Native 边界传对象在 HarmonyOS `javaScriptProxy` 里不稳定（不同版本行为不一）。统一用 JSON string 最稳，native 端 `JSON.parse`。性能开销可忽略（params 通常很小）。

### 为什么支持多次回调（finish 参数）

业务场景：
- 密码键盘：用户输错密码 → 中间进度 → 最终结果
- 文件上传：进度回调 → 完成回调
- 协议弹窗：滚动到末尾（进度）→ 用户同意（结果）

用同一个 callbackId，native 多次调 `progress(cbId, ...)`（finish=false），最后调 `resolve(cbId, ...)`（finish=true）。H5 端 SDK 看到 `finished=true` 才释放 callback。

### 为什么不用 Promise

Promise 只能 resolve 一次，不支持多次回调。Callback 模式更灵活。

### 为什么 Plugin 体系暂不动

Plugin 体系在 entry，本期 Common 改造不动它。后续真要用时，写一个 `PluginAdapter`：

```ts
import { BridgeHandler } from 'common'
import { BasePlugin } from '../plugins/core/BasePlugin'

export class PluginAdapter extends BridgeHandler {
  name: string

  constructor(private plugin: BasePlugin) {
    super()
    this.name = plugin.name
  }

  onCall(method: string, params: Record<string, Object>, cbId: string): void {
    this.plugin.handleMethod(method, params).then((result) => {
      this.resolve(cbId, result.data, result.message)
    })
  }
}
```

一行适配就能复用所有 BasePlugin 子类。

---

## 七、实施顺序

1. **删除 Hybrid 模块**
   - `rm -rf Hybrid`
   - 改根 `build-profile.json5`

2. **Common 新增文件**（顺序）
   - `bridge/BridgeResult.ets`
   - `bridge/BridgeCallbackPort.ets`
   - `bridge/BridgeHandler.ets`
   - `bridge/SNPBridge.ets`
   - `bridge/SystemHandler.ets`
   - `components/SNPWebView.ets`
   - `resources/rawfile/snp-bridge.js`

3. **更新 `Common/Index.ets`** 导出

4. **entry 接入验证**
   - 新建 `entry/src/main/resources/rawfile/bridge-test.html`
   - 新建 `entry/src/main/ets/pages/WebviewTest.ets`（NavDestination）
   - 在 `Index.ets` 加跳转 WebviewTest 的按钮 + PageMap 映射
   - `EntryAbility`（或 `Index.aboutToAppear`）注册 SystemHandler

5. **跑起来验证** → toast 能弹、device info 能回显

---

## 八、风险与回滚

| 风险 | 应对 |
|---|---|
| `javaScriptProxy` 的 `object` 不能传单例（必须 struct 实例） | 退路：在 SNPWebView 组件内部持有一个 wrapper struct field，把 `SNPBridge.getInstance().call` 转发出去 |
| `runJavaScript` 在某些情况下不执行（页面未加载完） | 加 `onPageStateChange` 监听，缓存 callbackId 直到页面就绪 |
| `import type` 在 ArkTS 不被支持（循环引用） | 用方案 B：BridgeResult 独立 + BridgeCallbackPort 接口，避免 BridgeHandler 反向 import SNPBridge |
| UIContext 在 EntryAbility 阶段取不到（`getUIContext` 返回 null） | 改在 Index 组件的 `aboutToAppear` 里 `SNPBridge.getInstance().init(this.getUIContext())` |
| 多 SNPWebView 实例时 `bindWebView` 互相覆盖 | 本期假设单实例。多实例后续加 webviewId 维度区分 |

**回滚**：所有改动可通过 `git checkout` 单文件还原，Hybrid 模块也能从 git 恢复。

---

## 九、不在本次范围

1. **业务 module**（PasswordModule / FaceModule / SignatureModule）—— 后续按 BridgeHandler 模式逐个建
2. **Plugin 体系适配**（PluginAdapter）—— 后续按需
3. **Cookie / UA / 离线包管理** —— 后续单独立项
4. **多 WebView 实例隔离** —— 当前单实例够用
5. **调试工具**（H5 console 拦截、bridge 日志面板）—— 后续
6. **安全校验**（origin 白名单、签名校验）—— 后续

---

## 十、关键文件路径速查

**删除：**
- `HelloHarmony/Hybrid`（整目录）

**修改：**
- `HelloHarmony/build-profile.json5`（移除 Hybrid 模块注册）
- `HelloHarmony/Common/Index.ets`（加导出）

**新建（Common）：**
- `Common/src/main/ets/bridge/BridgeResult.ets`
- `Common/src/main/ets/bridge/BridgeCallbackPort.ets`
- `Common/src/main/ets/bridge/BridgeHandler.ets`
- `Common/src/main/ets/bridge/SNPBridge.ets`
- `Common/src/main/ets/bridge/SystemHandler.ets`
- `Common/src/main/ets/components/SNPWebView.ets`
- `Common/src/main/resources/rawfile/snp-bridge.js`

**新建（entry，验证用）：**
- `entry/src/main/resources/rawfile/bridge-test.html`
- `entry/src/main/ets/pages/WebviewTest.ets`
- 修改 `entry/src/main/ets/pages/Index.ets`（加跳转按钮 + PageMap 映射）
- 修改 `entry/src/main/ets/entryability/EntryAbility.ets`（init + register）

**参考：**
- 单例范式：`Common/src/main/ets/router/SNPRouter.ets`
- 现有 Plugin 体系：`entry/src/main/ets/plugins/core/`（不动，后续适配）
