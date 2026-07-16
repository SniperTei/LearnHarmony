import { UIContext } from '@kit.ArkUI'

/**
 * PopupUtil 传给弹窗 builder 的统一参数容器。
 *
 * 为什么用具体类而非泛型元组：
 * ArkTS 严格模式下 WrappedBuilder / ComponentContent 的泛型必须满足 Object[]，
 * 且 ComponentContent 是不变（invariant）的——ComponentContent<具体类型> 不能
 * 赋给 ComponentContent<Object>。因此内部统一用具体类 PopupParams，
 * 泛型 T 只留在 API 表层（show<T>）做调用方类型安全，内部擦除为 Object。
 */
export class PopupParams {
  /** 弹窗数据（由具体 Builder 解析） */
  data: Object
  /** 关闭/确认回调出口（弹窗内部按钮调它来关闭并回传结果） */
  actions: PopupActions

  constructor(data: Object, actions: PopupActions) {
    this.data = data
    this.actions = actions
  }
}

/**
 * PopupUtil 传给 Builder 的回调出口。
 * 弹窗内部 UI（按钮等）调这些方法来关闭弹窗并回传结果。
 *
 * 用 class 而非 interface：ArkTS 严格模式（arkts-no-untyped-obj-literals）
 * 在闭包捕获场景下不认裸对象字面量，用 new 最稳。
 */
export class PopupActions {
  /** 确认并关闭 */
  confirm: () => void
  /** 取消并关闭，回传 reason 给 onCancel */
  cancel: (reason: string) => void
  /** 仅关闭，不触发任何回调（用于 dismiss() 主动关闭场景） */
  close: () => void

  constructor(confirm: () => void, cancel: (reason: string) => void, close: () => void) {
    this.confirm = confirm
    this.cancel = cancel
    this.close = close
  }
}

/**
 * 弹窗构建器接口
 *
 * 每个自定义弹窗实现这个接口，把"数据 → UI"的映射封装起来。
 * PopupUtil 不 import 任何具体弹窗，只通过 register 注册 + type 字符串分发，
 * 符合开闭原则：新增弹窗不改 PopupUtil。
 *
 * 实现说明：
 * ArkUI 的 @Builder 必须挂在 struct 上或为模块级函数，不能写在普通 class 里。
 * 因此实现类通常是 class（实现本接口），内部用 wrapBuilder 包装一个模块级
 * @Builder 函数。build() 返回 WrappedBuilder<[PopupParams]>，参数类型固定。
 *
 * @param T 弹窗数据类型（由实现者定义，调用方 show<T> 时传入，仅用于类型安全）
 */
export interface PopupBuilder<T extends Object> {
  /** 弹窗类型标识，需与 register 时的 key 一致 */
  readonly type: string

  /**
   * 构建弹窗内容的 builder 函数。
   * 返回的 WrappedBuilder 会被包装进 ComponentContent<PopupParams>。
   */
  build(): WrappedBuilder<[PopupParams]>
}
