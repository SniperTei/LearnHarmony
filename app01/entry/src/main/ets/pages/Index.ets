@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  build() {
    Row() {
      Column() {
        // width 默认单位是vp
        // Image('https://n.sinaimg.cn/sinakd20114/87/w1080h607/20211103/a3b1-942bf295a8a310b8c6bc8774253f01a6.jpg').width(250)
        // Image('https://n.sinaimg.cn/sinakd20114/87/w1080h607/20211103/a3b1-942bf295a8a310b8c6bc8774253f01a6.jpg').width('100%')
        Image($r('app.media.app_icon')).width(200).interpolation(ImageInterpolation.High)
        Text($r('app.string.hello_text'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
  }
}