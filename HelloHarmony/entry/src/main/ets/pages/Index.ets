import { HttpClient, HttpConfig, HttpMethod, HttpResponse, LogInterceptor, CommonHeaderInterceptor, HttpClientHolder } from 'network'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'
import { UserApi } from '../constants/ApiPaths'

const TAG = 'Index'

/** 环境配置 */
interface EnvOption {
  name: string
  baseUrl: string
}

const ENV_LIST: EnvOption[] = [
  { name: '开发', baseUrl: 'http://115.191.30.167:8041' },
  { name: '测试', baseUrl: 'http://test.example.com' },
  { name: '生产', baseUrl: 'https://prod.example.com' },
]

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

/** 用户列表 data 部分 */
interface UserListData {
  users: UserInfo[]
  total: number
  page: number
  page_size: number
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World'
  @State users: UserInfo[] = []
  @State totalCount: number = 0
  @State currentEnv: string = '未选择'
  @State envSelected: boolean = false
  @State loading: boolean = false
  @State loginResult: string = ''
  private client: HttpClient | null = null

  aboutToAppear(): void {
    HttpClientHolder.getInstance().init(new HttpConfig(), [
      new CommonHeaderInterceptor(),
      new LogInterceptor(),
    ])
    this.client = HttpClientHolder.getInstance().getClient()
    this.showEnvDialog()
  }

  build() {
    Column() {
      // 顶部环境栏
      Row() {
        Text(`当前环境: ${this.currentEnv}`)
          .fontSize(14)
          .fontColor('#666666')
        Blank()
        Text('切换')
          .fontSize(14)
          .fontColor('#007DFF')
          .onClick(() => this.showEnvDialog())
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // 接口测试入口
      Button('接口测试')
        .fontSize(14)
        .margin({ left: 16, top: 8 })
        .onClick(() => router.pushUrl({ url: 'pages/ZhengTest' }))

      // 标题 + 按钮
      Row() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('登录')
          .fontSize(14)
          .enabled(this.envSelected && !this.loading)
          .opacity(this.envSelected && !this.loading ? 1 : 0.4)
          .onClick(() => this.login())
        Button('获取用户列表')
          .fontSize(14)
          .enabled(this.envSelected && !this.loading)
          .opacity(this.envSelected && !this.loading ? 1 : 0.4)
          .onClick(() => this.fetchUsers())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 用户数量
      if (this.users.length > 0) {
        Text(`共 ${this.totalCount} 个用户`)
          .fontSize(13)
          .fontColor('#999999')
          .width('100%')
          .padding({ left: 16, bottom: 8 })
      }

      // 登录结果
      if (this.loginResult) {
        Text(this.loginResult)
          .fontSize(13)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, bottom: 8 })
      }

      // 加载提示
      if (this.loading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color('#007DFF')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(40)
      }

      // 用户列表
      if (this.users.length > 0) {
        List({ space: 8 }) {
          ForEach(this.users, (user: UserInfo) => {
            ListItem() {
              this.UserCard(user)
            }
          }, (user: UserInfo) => user.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12 })
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 用户卡片 */
  @Builder
  UserCard(user: UserInfo) {
    Column() {
      // 用户名 + 状态
      Row() {
        Text(user.username)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(user.is_active ? '活跃' : '停用')
          .fontSize(12)
          .fontColor(user.is_active ? '#4CAF50' : '#F44336')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor(user.is_active ? '#E8F5E9' : '#FFEBEE')
      }
      .width('100%')

      // 邮箱
      Text(user.email)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 4 })
        .width('100%')

      // 手机号
      if (user.mobile) {
        Text(user.mobile)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 2 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  /** 显示环境选择弹窗 */
  private showEnvDialog(): void {
    const sheets: SheetInfo[] = []
    for (let i = 0; i < ENV_LIST.length; i++) {
      const sheet: SheetInfo = {
        title: ENV_LIST[i].name,
        action: () => this.onEnvSelected(i)
      }
      sheets.push(sheet)
    }
    ActionSheet.show({
      title: '选择服务器环境',
      message: '请选择要连接的服务器地址',
      confirm: {
        value: '取消',
        action: () => {}
      },
      sheets: sheets
    })
  }

  /** 环境选中回调 */
  private onEnvSelected(index: number): void {
    const env = ENV_LIST[index]
    this.currentEnv = env.name
    this.client!.getConfig().baseUrl = env.baseUrl
    this.envSelected = true
    this.message = `已切换到 ${env.name} 环境`
    this.users = []
    hilog.info(0, TAG, `环境切换: ${env.name} → ${env.baseUrl}`)
  }

  private async login(): Promise<void> {
    if (!this.client) {
      return
    }
    this.loading = true
    try {
      const loginParams: Record<string, string> = {
        'identifier': '13013001300',
        'password': 'test1234'
      }
      const response: HttpResponse<LoginData> = await this.client
        .newRequest(UserApi.LOGIN, {
          method: HttpMethod.POST,
          params: loginParams,
        })
        .buildCall()
        .execute<LoginData>()

      if (response.isSuccess() && response.data) {
        this.loginResult = `登录成功: ${response.data.user.username}, token: ${response.data.access_token}`
      } else {
        this.loginResult = `登录失败: ${response.msg}`
      }
      hilog.info(0, TAG, `login response: code=${response.code}, msg=${response.msg}`)
    } catch (e) {
      this.loginResult = `登录异常: ${(e as Error).message}`
      hilog.error(0, TAG, `login error: ${(e as Error).message}`)
    } finally {
      this.loading = false
    }
  }

  private async fetchUsers(): Promise<void> {
    if (!this.client) {
      return
    }
    this.loading = true
    try {
      const params: Record<string, string> = {}
      params['page'] = '1'
      params['page_size'] = '10'
      const response: HttpResponse<UserListData> = await this.client
        .newRequest(UserApi.USER_LIST, {
          method: HttpMethod.GET,
          params: params,
        })
        .buildCall()
        .execute<UserListData>()

      if (response.isSuccess() && response.data) {
        this.message = '请求成功'
        this.users = response.data.users
        this.totalCount = response.data.total
      } else {
        this.message = `请求失败: ${response.msg}`
        this.users = []
      }
      hilog.info(0, TAG, `response: code=${response.code}, msg=${response.msg}`)
    } catch (e) {
      this.message = `异常: ${(e as Error).message}`
      this.users = []
      hilog.error(0, TAG, `fetchUsers error: ${(e as Error).message}`)
    } finally {
      this.loading = false
    }
  }
}
