import { ComponentResult } from '../../core/ComponentResult'

/**
 * 读卡读证厂商接口
 * 不同厂商实现此接口，实现多态切换
 */
export interface ICardReaderVendor {
  /** 厂商名称 */
  vendorName: string

  /** 读卡 */
  readCard(cardType: string): Promise<ComponentResult>
}
