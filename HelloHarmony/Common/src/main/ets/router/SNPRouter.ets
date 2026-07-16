import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'SNPRouter'

/**
 * 单例路由器，封装 NavPathStack
 *
 * 用法：
 *   // 容器绑定（Index.ets 的 Navigation）
 *   Navigation(SNPRouter.getInstance().getStack()) { ... }
 *
 *   // 前进（无返回值）
 *   SNPRouter.getInstance().forward(SNPPage.DeviceAuth)
 *
 *   // 前进并接收结果
 *   SNPRouter.getInstance().forward(SNPPage.QrScanPage, { source: 'index' }, (result) => {
 *     this.scanResult = result as string
 *   })
 *
 *   // 返回（带结果）
 *   SNPRouter.getInstance().back({ code: 'xxx' })
 */
export class SNPRouter {
  private static instance: SNPRouter | null = null
  private stack: NavPathStack = new NavPathStack()

  private constructor() {}

  static getInstance(): SNPRouter {
    if (!SNPRouter.instance) {
      SNPRouter.instance = new SNPRouter()
    }
    return SNPRouter.instance
  }

  /** 暴露给 Navigation 容器绑定 */
  getStack(): NavPathStack {
    return this.stack
  }

  /**
   * 前进到指定页面
   * @param name    页面名（SNPPage 常量）
   * @param param   传递给目标页的参数
   * @param onPop   目标页 pop 时触发的回调，收到返回结果
   */
  forward(name: string, param?: Object, onPop?: (result: Object) => void): void {
    this.stack.pushDestination({
      name: name,
      param: param,
      onPop: (info: PopInfo) => {
        if (onPop) {
          onPop(info.result)
        }
      }
    }).catch((e: Error) => {
      hilog.error(0, TAG, `forward [${name}] error: ${e.message}`)
    })
  }

  /** 返回上一页，可携带结果 */
  back(result?: Object): void {
    this.stack.pop(result)
  }

  /** 返回到栈中名为 name 的页面，可携带结果（popToName 原生支持 result） */
  backTo(name: string, result?: Object): void {
    this.stack.popToName(name, result)
  }

  /**
   * 去重导航：栈中已有该页就提到栈顶，没有才 push
   * 适用于"首页 tab"/"购物车"这种单例页
   * @return true=已存在并提到栈顶，false=栈里没有，走 forward 新推
   */
  moveToTop(name: string, param?: Object, onPop?: (result: Object) => void): boolean {
    // NavPathStack.moveToTop 返回 void，需手动查栈判断是否存在
    const found: boolean = this.stack.getAllPathName().includes(name)
    if (found) {
      this.stack.moveToTop(name)
    } else {
      this.forward(name, param, onPop)
    }
    return found
  }

  /** 替换栈顶（不增加栈深度） */
  replace(name: string, param?: Object): void {
    this.stack.replacePath({ name: name, param: param })
  }

  /** 清空整个栈 */
  clear(): void {
    this.stack.clear()
  }

  /** 当前页（栈顶）获取参数 */
  getParam<T>(): T {
    const param: ESObject = this.stack.getParamByIndex(this.stack.size() - 1)
    return param as T
  }

  /** 栈深度 */
  size(): number {
    return this.stack.size()
  }
}
