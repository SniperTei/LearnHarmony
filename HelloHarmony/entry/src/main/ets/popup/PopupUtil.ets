import { hilog } from '@kit.PerformanceAnalysisKit'
import { ComponentContent, promptAction, UIContext } from '@kit.ArkUI'
import { PopupBuilder, PopupActions, PopupParams } from './PopupBuilder'
import { PopupConfig } from './PopupConfig'

const TAG = 'PopupUtil'

/**
 * 一个正在显示的弹窗实例
 */
class PopupInstance {
  /** 唯一 id（dismiss 用） */
  readonly id: string
  /** 弹窗内容句柄（用于关闭） */
  content: ComponentContent<PopupParams>
  /** 类型标识 */
  type: string
  /** 是否已关闭（防重复关闭） */
  closed: boolean = false

  constructor(id: string, content: ComponentContent<PopupParams>, type: string) {
    this.id = id
    this.content = content
    this.type = type
  }
}

/**
 * 全局弹窗工具（单例）
 *
 * 能力：
 * - 任意类（含非组件类）调用 show() 弹出自定义弹窗
 * - 模态栈式叠加：A 不关时弹 B，A 不可交互，B 关闭后回到 A
 * - 返回键 / 遮罩点击只关栈顶（通过 onWillDismiss 拦截）
 * - 注册式扩展：新增弹窗不改本类
 *
 * 前置条件：App 启动时必须先调 init(uiContext) 注入 UIContext，
 * 否则 show() 会打日志并直接返回 null。
 *
 * 用法：
 * ```
 * // 1. 启动时注入（Index.aboutToAppear 里）
 * PopupUtil.getInstance().init(this.getUIContext())
 *
 * // 2. 注册弹窗 Builder
 * PopupUtil.getInstance().register('helloDialog', new HelloDialogBuilder())
 *
 * // 3. 任意类里弹出
 * PopupUtil.getInstance().show<HelloDialogData>('helloDialog', {
 *   data: { message: 'Hello!' },
 *   onConfirm: () => { ... },
 *   onCancel: (reason) => { ... }
 * })
 * ```
 */
export class PopupUtil {
  private static instance: PopupUtil | null = null
  private uiContext: UIContext | null = null
  /** 已注册的 Builder（type → builder） */
  private builders: Map<string, PopupBuilder<Object>> = new Map()
  /** 弹窗栈：栈顶是最后弹出的（最上层） */
  private stack: PopupInstance[] = []
  /** id 自增种子 */
  private idSeed: number = 0

  private constructor() {}

  static getInstance(): PopupUtil {
    if (!PopupUtil.instance) {
      PopupUtil.instance = new PopupUtil()
    }
    return PopupUtil.instance
  }

  /** 注入 UIContext（App 启动时调一次） */
  init(uiContext: UIContext): void {
    this.uiContext = uiContext
    hilog.info(0, TAG, 'UIContext injected')
  }

  /** 注册弹窗 Builder */
  register<T extends Object>(type: string, builder: PopupBuilder<T>): void {
    if (this.builders.has(type)) {
      hilog.warn(0, TAG, `Builder [${type}] 已存在，将被覆盖`)
    }
    this.builders.set(type, builder as PopupBuilder<Object>)
    hilog.info(0, TAG, `Builder registered: ${type}`)
  }

  /** 注销 */
  unregister(type: string): void {
    this.builders.delete(type)
  }

  /**
   * 弹出弹窗
   *
   * @param type   注册时的类型标识
   * @param config 弹窗配置（数据 + 回调）
   * @returns 弹窗 id（用于 dismiss），失败返回 null
   */
  show<T extends Object>(type: string, config: PopupConfig<T>): string | null {
    if (!this.uiContext) {
      hilog.error(0, TAG, `show 失败：UIContext 未初始化（type=${type}）`)
      return null
    }
    const builder = this.builders.get(type)
    if (!builder) {
      hilog.error(0, TAG, `show 失败：未注册的 type [${type}]`)
      return null
    }

    const ctx = this.uiContext
    const modal = config.modal ?? true
    const autoDismiss = config.autoDismiss ?? true
    const self = this
    // 生成唯一 id（actions 闭包要用，必须先声明）
    const id: string = `popup_${++this.idSeed}`

    // 构造 actions（弹窗内部按钮调它来关闭并回传结果）
    const actions: PopupActions = new PopupActions(
      (): void => {            // confirm
        config.onConfirm?.()
        if (autoDismiss) {
          self.dismissById(id)
        }
      },
      (reason: string): void => {   // cancel
        config.onCancel?.(reason)
        if (autoDismiss) {
          self.dismissById(id)
        }
      },
      (): void => {            // close
        self.dismissById(id)
      }
    )

    // 用 Builder 构建内容
    const wrapped = builder.build()
    const params = new PopupParams(config.data, actions)
    const content = new ComponentContent<PopupParams>(ctx, wrapped, params)

    const options: promptAction.BaseDialogOptions = {
      isModal: modal,
      alignment: DialogAlignment.Center,
      autoCancel: false,
      maskColor: '#66000000',
      onWillDismiss: (action: DismissDialogAction): void => {
        if (action.reason === DismissReason.PRESS_BACK || action.reason === DismissReason.TOUCH_OUTSIDE) {
          const reason = action.reason === DismissReason.PRESS_BACK ? 'back' : 'mask'
          config.onCancel?.(reason)
          self.dismissById(id)
          action.dismiss()
        }
      }
    }

    ctx.getPromptAction()
      .openCustomDialog(content, options)
      .then((): void => {
        const instance = new PopupInstance(id, content, type)
        this.stack.push(instance)
        hilog.info(0, TAG, `show [${type}] ok, id=${id}, stack=${this.stack.length}`)
      })
      .catch((e: Error): void => {
        hilog.error(0, TAG, `show [${type}] 失败: ${e.message}`)
        content.dispose()
      })

    return id
  }

  /** 关闭指定弹窗（按 id） */
  dismiss(id: string): void {
    this.dismissById(id)
  }

  /** 关闭栈顶弹窗 */
  dismissTop(): void {
    if (this.stack.length === 0) {
      return
    }
    this.closeInstance(this.stack[this.stack.length - 1])
  }

  /** 关闭所有弹窗（从栈顶往下） */
  dismissAll(): void {
    while (this.stack.length > 0) {
      this.closeInstance(this.stack[this.stack.length - 1])
    }
    hilog.info(0, TAG, 'dismissAll done')
  }

  /** 当前栈深度 */
  depth(): number {
    return this.stack.length
  }

  // ---- 内部 ----

  private dismissById(id: string): void {
    for (let i = 0; i < this.stack.length; i++) {
      if (this.stack[i].id === id) {
        this.closeInstance(this.stack[i])
        return
      }
    }
  }

  /** 关闭单个实例（从栈中移除 + 调系统关闭 + 延迟释放节点） */
  private closeInstance(inst: PopupInstance): void {
    if (inst.closed) {
      return
    }
    inst.closed = true
    const idx = this.stack.indexOf(inst)
    if (idx >= 0) {
      this.stack.splice(idx, 1)
    }
    this.uiContext?.getPromptAction().closeCustomDialog(inst.content)
    setTimeout((): void => { inst.content.dispose() }, 300)
    hilog.info(0, TAG, `close id=${inst.id}, stack=${this.stack.length}`)
  }
}
