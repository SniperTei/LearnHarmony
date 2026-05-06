/**
 * 组件统一返回结果
 */
export class ComponentResult {
  code: number = 0
  data: Record<string, Object> | null = null
  message: string = 'success'

  static success(data: Record<string, Object> | null = null, message: string = 'success'): ComponentResult {
    const result = new ComponentResult()
    result.code = 0
    result.data = data
    result.message = message
    return result
  }

  static error(code: number, message: string): ComponentResult {
    const result = new ComponentResult()
    result.code = code
    result.message = message
    return result
  }

  toJSON(): string {
    return JSON.stringify({
      code: this.code,
      data: this.data,
      message: this.message
    })
  }
}
