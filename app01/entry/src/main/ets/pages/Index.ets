import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  @State imgWidth: number = 30

  @State strSelectedDate: string = '1900-01-01'

  @State datePickerVisibleFlag: boolean = false

  @State isLunar: boolean = false
  private selectedDate: Date = new Date('2021-08-08')

  build() {
    Row() {
      Column() {
        // width 默认单位是vp
        // Image('https://n.sinaimg.cn/sinakd20114/87/w1080h607/20211103/a3b1-942bf295a8a310b8c6bc8774253f01a6.jpg').width(250)
        // Image('https://n.sinaimg.cn/sinakd20114/87/w1080h607/20211103/a3b1-942bf295a8a310b8c6bc8774253f01a6.jpg').width('100%')
        Image($r('app.media.app_icon'))
          .width(this.imgWidth)
          .interpolation(ImageInterpolation.High)
        Text($r('app.string.hello_text'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        TextInput({placeholder: "please input username"})
          .style(TextInputStyle.Default)
          .width(300)
        TextInput({placeholder: "please input password"})
          .style(TextInputStyle.Default)
          .type(InputType.Password)
          .width(300)
          .maxLength(24)
        Button("Login", {type: ButtonType.Capsule, stateEffect: true})
          .onClick(() => {
            // toast login success
            promptAction.showToast({message: "Login Success"})
            if (this.imgWidth == 100) {
              this.imgWidth = 30;
            } else {
              this.imgWidth = 100;
            }
          })
        /*
        // 全选按钮
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          CheckboxGroup({ group: 'checkboxGroup' })
            .selectedColor('#007DFF')
            .onChange((itemName: CheckboxGroupResult) => {
              console.info("checkbox group content" + JSON.stringify(itemName))
            })
          Text('Select All').fontSize(14).lineHeight(20).fontColor('#182431').fontWeight(500)
        }.backgroundColor('#ff0000')

        // 选项1
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
            .selectedColor('#007DFF')
            .onChange((value: boolean) => {
              console.info('Checkbox1 change is' + value)
            })
          Text('Checkbox1').fontSize(14).lineHeight(20).fontColor('#182431').fontWeight(500)
        }.margin({ left: 36 })

        // 选项2
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Checkbox({ name: 'checkbox2', group: 'checkboxGroup' })
            .selectedColor('#007DFF')
            .onChange((value: boolean) => {
              console.info('Checkbox2 change is' + value)
            })
          Text('Checkbox2').fontSize(14).lineHeight(20).fontColor('#182431').fontWeight(500)
        }.margin({ left: 36 })

        // 选项3
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Checkbox({ name: 'checkbox3', group: 'checkboxGroup' })
            .selectedColor('#007DFF')
            .onChange((value: boolean) => {
              console.info('Checkbox3 change is' + value)
            })
          Text('Checkbox3').fontSize(14).lineHeight(20).fontColor('#182431').fontWeight(500)
        }.margin({ left: 36 }).backgroundColor('#00ff00')
        */
        DataPanel({values:[3, 3, 3, 1], max: 10, type: DataPanelType.Line}).height(10)
        Button('select date').onClick(() => {
          // 展示datepicker
          this.datePickerVisibleFlag = !this.datePickerVisibleFlag
        })
        Text(this.strSelectedDate)
        Slider({min: 0, max: 10, value: 6})
          .blockColor('#36d')
          .showTips(true)
          .trackThickness(10)
          .width(300)
          .onChange((value) => {
            console.log('change value : ', value)
          })
        DatePicker({
          start: new Date('1970-1-1'),
          end: new Date('2100-1-1'),
          selected: this.selectedDate
        })
          .lunar(this.isLunar)
          .onChange((value: DatePickerResult) => {
            // this.selectedDate.setFullYear(value.year, value.month, value.day)
            console.info('select current date is: ' + JSON.stringify(value))
          })
        // DatePicker().visibility(this.datePickerVisibleFlag ? Visibility.Visible : Visibility.Hidden)
        //   .onChange((date) => {
        //     // 打印选中的日期
        //     console.info('select current date is: ' + JSON.stringify(date))
        //     // this.strSelectedDate = date.year + "-" + date.month + "-" + date.day
        //     // this.datePickerVisibleFlag = false
        //   })
      }
      .width('100%')
    }
    .height('100%')
  }
}