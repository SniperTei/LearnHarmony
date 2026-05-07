import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0001

/** 日志策略接口，实现此接口即可替换底层日志引擎 */
export interface ILogger {
  debug(tag: string, msg: string): void
  info(tag: string, msg: string): void
  warn(tag: string, msg: string): void
  error(tag: string, msg: string): void
}

/** 默认实现：系统 hilog */
class HiLogger implements ILogger {
  debug(tag: string, msg: string): void {
    hilog.debug(DOMAIN, tag, msg)
  }

  info(tag: string, msg: string): void {
    hilog.info(DOMAIN, tag, msg)
  }

  warn(tag: string, msg: string): void {
    hilog.warn(DOMAIN, tag, msg)
  }

  error(tag: string, msg: string): void {
    hilog.error(DOMAIN, tag, msg)
  }
}

/**
 * 日志工具
 * 统一封装，支持通过 setLogger 替换底层实现
 */
export class LogUtil {
  private static logger: ILogger = new HiLogger()

  /** 替换日志引擎，在 Ability.onCreate 中调用 */
  static setLogger(logger: ILogger): void {
    LogUtil.logger = logger
  }

  static debug(tag: string, msg: string): void {
    LogUtil.logger.debug(tag, msg)
  }

  static info(tag: string, msg: string): void {
    LogUtil.logger.info(tag, msg)
  }

  static warn(tag: string, msg: string): void {
    LogUtil.logger.warn(tag, msg)
  }

  static error(tag: string, msg: string): void {
    LogUtil.logger.error(tag, msg)
  }
}
