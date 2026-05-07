/**
 * 日期格式化工具
 */
export class DateUtil {
  /**
   * 格式化时间戳
   * @param timestamp 毫秒时间戳
   * @param pattern 格式模板，默认 'YYYY-MM-DD HH:mm:ss'
   */
  static format(timestamp: number, pattern: string = 'YYYY-MM-DD HH:mm:ss'): string {
    const date = new Date(timestamp)
    const year = date.getFullYear().toString()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    const second = date.getSeconds().toString().padStart(2, '0')

    return pattern
      .replace('YYYY', year)
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hour)
      .replace('mm', minute)
      .replace('ss', second)
  }

  /** 格式化当前时间 */
  static formatNow(pattern: string = 'YYYY-MM-DD HH:mm:ss'): string {
    return DateUtil.format(Date.now(), pattern)
  }

  /**
   * ISO 日期字符串转格式化字符串
   * @param isoStr ISO 日期字符串，如 '2026-05-07T10:30:00.000Z'
   */
  static formatISO(isoStr: string, pattern: string = 'YYYY-MM-DD HH:mm:ss'): string {
    return DateUtil.format(new Date(isoStr).getTime(), pattern)
  }

  /** 友好时间显示（刚刚、x分钟前、x小时前、x天前） */
  static formatFriendly(timestamp: number): string {
    const now = Date.now()
    const diff = now - timestamp
    const seconds = Math.floor(diff / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    const days = Math.floor(hours / 24)

    if (seconds < 60) {
      return '刚刚'
    } else if (minutes < 60) {
      return `${minutes}分钟前`
    } else if (hours < 24) {
      return `${hours}小时前`
    } else if (days < 30) {
      return `${days}天前`
    } else {
      return DateUtil.format(timestamp, 'YYYY-MM-DD')
    }
  }
}
