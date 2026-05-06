import { HttpClientHolder, HttpMethod, HttpResponse } from '../network'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'

const TAG = 'ZhengTest'

@Entry
@Component
struct ZhengTest {
  @State loading: boolean = false
  @State result1: string = ''
  @State result2: string = ''
  @State result3: string = ''
  @State result4: string = ''

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => router.back())
        Text('接口测试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        if (this.loading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#007DFF')
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // 按钮区域
      Column({ space: 12 }) {
        Button('测试接口 1')
          .width('100%')
          .enabled(!this.loading)
          .onClick(() => this.testApi1())

        Text(this.result1)
          .fontSize(13)
          .fontColor('#333333')
          .width('100%')
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button('测试接口 2')
          .width('100%')
          .enabled(!this.loading)
          .onClick(() => this.testApi2())

        Text(this.result2)
          .fontSize(13)
          .fontColor('#333333')
          .width('100%')
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button('测试接口 3')
          .width('100%')
          .enabled(!this.loading)
          .onClick(() => this.testApi3())

        Text(this.result3)
          .fontSize(13)
          .fontColor('#333333')
          .width('100%')
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button('测试接口 4')
          .width('100%')
          .enabled(!this.loading)
          .onClick(() => this.testApi4())

        Text(this.result4)
          .fontSize(13)
          .fontColor('#333333')
          .width('100%')
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
  }

  private async testApi1(): Promise<void> {
    this.result1 = '请求中...'
    this.loading = true
    try {
      // TODO: 替换为实际接口
      const client = HttpClientHolder.getInstance().getClient()
      const response: HttpResponse<Object> = await client
        .newRequest('/api/v1/test1', { method: HttpMethod.GET })
        .buildCall()
        .execute<Object>()
      this.result1 = `code=${response.code}, msg=${response.msg}, data=${JSON.stringify(response.data)}`
    } catch (e) {
      this.result1 = `异常: ${(e as Error).message}`
      hilog.error(0, TAG, `testApi1 error: ${(e as Error).message}`)
    } finally {
      this.loading = false
    }
  }

  private async testApi2(): Promise<void> {
    this.result2 = '请求中...'
    this.loading = true
    try {
      // TODO: 替换为实际接口
      const client = HttpClientHolder.getInstance().getClient()
      const response: HttpResponse<Object> = await client
        .newRequest('/api/v1/test2', { method: HttpMethod.GET })
        .buildCall()
        .execute<Object>()
      this.result2 = `code=${response.code}, msg=${response.msg}, data=${JSON.stringify(response.data)}`
    } catch (e) {
      this.result2 = `异常: ${(e as Error).message}`
      hilog.error(0, TAG, `testApi2 error: ${(e as Error).message}`)
    } finally {
      this.loading = false
    }
  }

  private async testApi3(): Promise<void> {
    this.result3 = '请求中...'
    this.loading = true
    try {
      // TODO: 替换为实际接口
      const client = HttpClientHolder.getInstance().getClient()
      const response: HttpResponse<Object> = await client
        .newRequest('/api/v1/test3', { method: HttpMethod.POST, params: {} })
        .buildCall()
        .execute<Object>()
      this.result3 = `code=${response.code}, msg=${response.msg}, data=${JSON.stringify(response.data)}`
    } catch (e) {
      this.result3 = `异常: ${(e as Error).message}`
      hilog.error(0, TAG, `testApi3 error: ${(e as Error).message}`)
    } finally {
      this.loading = false
    }
  }

  private async testApi4(): Promise<void> {
    this.result4 = '请求中...'
    this.loading = true
    try {
      // TODO: 替换为实际接口
      const client = HttpClientHolder.getInstance().getClient()
      const response: HttpResponse<Object> = await client
        .newRequest('/api/v1/test4', { method: HttpMethod.POST, params: {} })
        .buildCall()
        .execute<Object>()
      this.result4 = `code=${response.code}, msg=${response.msg}, data=${JSON.stringify(response.data)}`
    } catch (e) {
      this.result4 = `异常: ${(e as Error).message}`
      hilog.error(0, TAG, `testApi4 error: ${(e as Error).message}`)
    } finally {
      this.loading = false
    }
  }
}
