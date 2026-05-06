import { ComponentResult } from '../../core/ComponentResult'
import { ICardReaderVendor } from './ICardReaderVendor'

/**
 * 厂商A 实现
 * TODO: 接入厂商A的 SDK
 */
export class VendorAReader implements ICardReaderVendor {
  vendorName: string = 'VendorA'

  async readCard(cardType: string): Promise<ComponentResult> {
    // TODO: 调用厂商A SDK
    return ComponentResult.error(-1, 'VendorA not implemented')
  }
}
