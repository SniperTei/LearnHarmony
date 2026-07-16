/**
 * Popup 展示配置
 *
 * @param data        传给弹窗的数据（由具体 Builder 定义类型）
 * @param onConfirm   用户确认时回调
 * @param onCancel    用户取消时回调（点遮罩 / 返回键 / 取消按钮）
 * @param modal       是否模态（默认 true：下层弹窗不可交互）
 * @param autoDismiss 确认/取消后是否自动关闭弹窗（默认 true）
 */
export interface PopupConfig<T> {
  data: T
  onConfirm?: () => void
  onCancel?: (reason: string) => void
  modal?: boolean
  autoDismiss?: boolean
}
