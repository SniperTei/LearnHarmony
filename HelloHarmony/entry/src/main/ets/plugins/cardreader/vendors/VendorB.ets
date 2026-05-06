import { ComponentResult } from '../../core/ComponentResult'
import { ICardReaderVendor } from './ICardReaderVendor'

/**
 * 厂商B 实现
 * TODO: 接入厂商B的 SDK
 */
export class VendorBReader implements ICardReaderVendor {
  vendorName: string = 'VendorB'

  async readCard(cardType: string): Promise<ComponentResult> {
    // TODO: 调用厂商B SDK
    return ComponentResult.error(-1, 'VendorB not implemented')
  }
}
