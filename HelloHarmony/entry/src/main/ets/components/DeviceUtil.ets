import deviceInfo from '@ohos.deviceInfo'
import { display } from '@kit.ArkUI'

/** 设备信息 */
export interface DeviceData {
  /** 设备品牌（如 HUAWEI） */
  brand: string
  /** 设备型号（如 Mate 60 Pro） */
  productModel: string
  /** 设备类型（phone / tablet / tv / wearable） */
  deviceType: string
  /** 设备名称 */
  deviceName: string
  /** 系统版本（如 HarmonyOS 5.0.0） */
  osFullName: string
  /** SDK API 版本号 */
  sdkApiVersion: number
  /** 屏幕宽度（px） */
  screenWidth: number
  /** 屏幕高度（px） */
  screenHeight: number
  /** 屏幕密度（DPI） */
  densityDPI: number
  /** 屏幕像素密度倍数 */
  densityPixels: number
}

/**
 * 设备信息工具
 * 获取设备型号、系统版本、屏幕参数等
 */
export class DeviceUtil {

  /** 获取全部设备信息 */
  static getDeviceInfo(): DeviceData {
    const disp = display.getDefaultDisplaySync()
    return {
      brand: deviceInfo.brand,
      productModel: deviceInfo.productModel,
      deviceType: DeviceUtil.getDeviceTypeName(),
      deviceName: deviceInfo.marketName,
      osFullName: deviceInfo.osFullName,
      sdkApiVersion: deviceInfo.sdkApiVersion,
      screenWidth: disp.width,
      screenHeight: disp.height,
      densityDPI: disp.densityDPI,
      densityPixels: disp.densityPixels
    }
  }

  /** 设备品牌 */
  static getBrand(): string {
    return deviceInfo.brand
  }

  /** 设备型号 */
  static getModel(): string {
    return deviceInfo.productModel
  }

  /** 系统版本 */
  static getOsFullName(): string {
    return deviceInfo.osFullName
  }

  /** SDK API 版本号 */
  static getSdkApiVersion(): number {
    return deviceInfo.sdkApiVersion
  }

  /** 设备市场名称 */
  static getMarketName(): string {
    return deviceInfo.marketName
  }

  /** 设备类型（phone / tablet / tv / wearable / car） */
  static getDeviceTypeName(): string {
    const typeMap: Record<string, string> = {
      'default': 'phone',
      'tablet': 'tablet',
      'tv': 'tv',
      'wearable': 'wearable',
      'car': 'car'
    }
    return typeMap[deviceInfo.deviceType] ?? deviceInfo.deviceType
  }

  /** 是否为手机 */
  static isPhone(): boolean {
    return deviceInfo.deviceType === 'default'
  }

  /** 是否为平板 */
  static isTablet(): boolean {
    return deviceInfo.deviceType === 'tablet'
  }

  /**
   * 设备序列号（需要系统签名权限）
   * 需在 module.json5 中声明 ohos.permission.sec.ACCESS_UDID
   */
  static getSerial(): string {
    return deviceInfo.serial
  }

  /**
   * 设备 UDID（需要系统签名权限）
   * 需在 module.json5 中声明 ohos.permission.sec.ACCESS_UDID
   */
  static getUDID(): string {
    return deviceInfo.udid
  }

  /** 屏幕宽度（px） */
  static getScreenWidth(): number {
    return display.getDefaultDisplaySync().width
  }

  /** 屏幕高度（px） */
  static getScreenHeight(): number {
    return display.getDefaultDisplaySync().height
  }

  /** 屏幕像素密度倍数 */
  static getDensityPixels(): number {
    return display.getDefaultDisplaySync().densityPixels
  }
}
