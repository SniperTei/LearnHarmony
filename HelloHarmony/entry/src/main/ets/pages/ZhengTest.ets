import { HttpClientHolder, HttpMethod } from '../network'
import { RequestHelper } from '../utils/RequestHelper'
import { StorageUtil, StorageKey } from '../utils/StorageUtil'
import { TitleBar } from '../base/TitleBar'
import { UserApi } from '../constants/ApiPaths'

const TAG = 'ZhengTest'

/** 用户信息 */
interface UserInfo {
  id: string
  email: string
  username: string
  mobile: string
  is_active: boolean
  created_at: string
  updated_at: string
}

/** 登录响应 data */
interface LoginData {
  access_token: string
  token_type: string
  user: UserInfo
}

@Entry
@Component
struct ZhengTest {
  @State loading: boolean = false
  @State result1: string = ''
  @State result2: string = ''
  @State result3: string = ''
  @State result4: string = ''

  private client = HttpClientHolder.getInstance().getClient()

  build() {
    Column() {
      TitleBar({ title: '接口测试', showBack: true, showLoading: this.loading })

      Scroll() {
        Column({ space: 12 }) {
          // 登录接口
          Button('登录接口')
            .width('100%')
            .enabled(!this.loading)
            .onClick(() => this.testLogin())

          Text(this.result1)
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .copyOption(CopyOptions.LocalDevice)

          // 获取用户列表
          Button('获取用户列表')
            .width('100%')
            .enabled(!this.loading)
            .onClick(() => this.testUserList())

          Text(this.result2)
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .copyOption(CopyOptions.LocalDevice)

          // 获取用户详情
          Button('获取用户详情')
            .width('100%')
            .enabled(!this.loading)
            .onClick(() => this.testUserDetail())

          Text(this.result3)
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .copyOption(CopyOptions.LocalDevice)

          // 退出登录
          Button('退出登录')
            .width('100%')
            .enabled(!this.loading)
            .onClick(() => this.testLogout())

          Text(this.result4)
            .fontSize(13)
            .fontColor('#333333')
            .width('100%')
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  /** 登录 */
  private testLogin(): void {
    RequestHelper.execute({
      tag: TAG,
      request: () => this.client
        .newRequest(UserApi.LOGIN, {
          method: HttpMethod.POST,
          params: { 'identifier': '13013001300', 'password': 'nan234561' }
        })
        .buildCall()
        .execute<LoginData>(),
      onStart: () => { this.loading = true; this.result1 = '请求中...' },
      onSuccess: (response) => {
        const data = response.data
        if (response.isSuccess() && data !== null) {
          // 存储登录数据
          StorageUtil.putObject<LoginData>(StorageKey.LOGIN_DATA, data)
          StorageUtil.saveToken(data.access_token)
          this.result1 =
            `msg: ${response.msg}\n` +
            `token: ${data.access_token}\n` +
            `用户名: ${data.user.username}\n` +
            `手机号: ${data.user.mobile}\n` +
            `邮箱: ${data.user.email}`
        } else {
          this.result1 = `失败: ${response.msg}`
        }
      },
      onError: (msg) => { this.result1 = `异常: ${msg}` },
      onFinish: () => { this.loading = false }
    })
  }

  /** 获取用户列表 */
  private testUserList(): void {
    RequestHelper.execute({
      tag: TAG,
      request: () => this.client
        .newRequest(UserApi.USER_LIST, {
          method: HttpMethod.GET,
          params: { 'page': '1', 'page_size': '10' }
        })
        .buildCall()
        .execute<Object>(),
      onStart: () => { this.loading = true; this.result2 = '请求中...' },
      onSuccess: (response) => {
        this.result2 = `code: ${response.code}\nmsg: ${response.msg}\n${JSON.stringify(response.data)}`
      },
      onError: (msg) => { this.result2 = `异常: ${msg}` },
      onFinish: () => { this.loading = false }
    })
  }

  /** 获取用户详情 */
  private testUserDetail(): void {
    RequestHelper.execute({
      tag: TAG,
      request: () => this.client
        .newRequest(UserApi.USER_DETAIL.replace('{id}', '2'), {
          method: HttpMethod.GET
        })
        .buildCall()
        .execute<Object>(),
      onStart: () => { this.loading = true; this.result3 = '请求中...' },
      onSuccess: (response) => {
        this.result3 = `code: ${response.code}\nmsg: ${response.msg}\n${JSON.stringify(response.data)}`
      },
      onError: (msg) => { this.result3 = `异常: ${msg}` },
      onFinish: () => { this.loading = false }
    })
  }

  /** 退出登录 */
  private testLogout(): void {
    RequestHelper.execute({
      tag: TAG,
      request: () => this.client
        .newRequest(UserApi.LOGOUT, { method: HttpMethod.POST })
        .buildCall()
        .execute<Object>(),
      onStart: () => { this.loading = true; this.result4 = '请求中...' },
      onSuccess: (response) => {
        this.result4 = `code: ${response.code}\nmsg: ${response.msg}`
      },
      onError: (msg) => { this.result4 = `异常: ${msg}` },
      onFinish: () => { this.loading = false }
    })
  }
}
