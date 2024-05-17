//item in MockData on the home page
import { AppInfo }from '../data/MockData_HomePage'
@Component
export default struct itemComponent{
  private appItem?:AppInfo

  //自定义传参方法
  @Builder
  createIcon(icon:Resource){
    Image(icon)
      .width(34)
      .height(34)
      .margin(15)
      .objectFit(ImageFit.Contain)
  }
  //layout
  build(){
    /**
     * In A ROW, the first element is icon, the second element is a taskText
     */
    Row(){
      //1. Icon
      this.createIcon(this.appItem.logo)
      //2. Texts(Name + Desc)
      Column() {
        // Name
        Text(this.appItem.name)//设置通用属性
          .fontSize(20)
          .fontWeight(500)//设置文字装饰  用变量进行条件渲染；注意，接口的参数传入都要在{}里面，引用参数名，后面加colon
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })

        //Desc
        Text(this.appItem.desc)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })

      }
      .alignItems(HorizontalAlign.Start)
      .width('70%')
      .justifyContent(FlexAlign.Start)


      //3. Get Button
      Button("Get",{ type: ButtonType.Normal, stateEffect: true })
        .borderRadius(15)
        .backgroundColor('#ff5786df')
        .width(50)
        .height(27)
        .fontWeight(FontWeight.Bold)
        .padding({right:0})
    }
    //为单行task设置圆角
    .borderRadius(24)
    .backgroundColor(Color.White)
    //如果是绝对值，不用引号；如果是相对值，需要引号
    .width('100%')


  }
}