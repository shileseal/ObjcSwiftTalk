## 这一集中我们回答一下过去几周中我们收到的问题，涵盖了网络，table views，栈视图，App类和测试。


这一集不一样，在于这是用于回答问题的。我们想知道你们是否喜欢，如果你有意见反馈的话，及时给我们发邮件。


### 存储验证信息
第一个问题，当你发一个网络请求的额时候，你在哪里存储验证信息。那是关于网络的那集，我们用Resource结构体来展示网络层。在很多案例中，我们必须给几乎每个请求使用验证token，因为大多数终端是被验证的。因此需要把token放到Webservice类里。

```Swift
final class Webservice {
    var authenticationToken: String?

    // ...
}
```
然后我们修改load方法中的网络请求，把token当做http header传进去。

如果业务逻辑中区分验证和非验证的请求很重要，可以把token放到Resource中。

### HTTP头
下一个问题：你在哪里添加HTTP头，头作为Content-Type，也关联到你是如果解析resource？一个像Content-Type的头放到Resource结构体中是很好的，这就在终端中明确了。举个栗子，我们可以增加一个叫做headers的字典。

```Swift
struct Resource<A> {
    let url: URL
    let method: HttpMethod<Data>
    let parse: (Data) -> A?
    let headers: [String: String]
}
```
我们也可以给header添加一个单独的属性。
```Swift
struct Resource<A> {
    let url: URL
    let method: HttpMethod<Data>
    let parse: (Data) -> A?
    let contentType: String?
}
```
拥有headers字典是更宽泛的，这也更加灵活。我们可以修改我们的JSON数据源来自动的设置Content-Type或者Accept-Type.比如我们想要接收XML我需要不同的解析方法，并且我们可以通过给Resource增加另外的构造器来解析方法和自动匹配Content-Type.

我们甚至可以结合着两个问题，在我们WebService的load方法中,我们可以增加两个header，一个是明确的Resource的header还有一个是其他所有数据源的header。

### 多种cell类型
下一个问题：如何扩展Generic Table View Controllers视频集中的方法使同一个tableView中处理不同的cell类型。

首先，我们认为使用protocol会简单，但是我们在实际中使用，这显得并不容易。我们的结论是这是可能的，但是我们的方法并没有像泛型table view Controller给一个单独的cell类型好用。举个栗子，一个简单的解决方案有一个大的缺点：我们需要把强制转换从我买的table View controller（the library）中移到配置闭包中（使用回调的地方）。现在在tableView(cellForRowAt:)，我们把我买的cell转成正确的类型让configue闭包调用正确的cell类型。

无论我们怎么解决这个问题，我们总是以拖鞋收场。我们没找到一个好的解决方案，如果有人发现，请告诉我们。

### 给ContentElement增加UITextView支持
另一个问题：在Stack Views with Enums视频集中，如果你想支持一个textView，如何处理这些闭包？因为一个textView有多个回调闭包。除非我们只有一个回调，我们可以用和.button相似的方法，但是在有多个回调的时候怎么办？

首先，ContentElement方法我们为了方便创建，所以这也许不是解决这个问题最好的工具。

其次，我们也可以给枚举增加一个自定义案例。这种方式，我们可以使用任何栈里面的视图并且我们传入一个完全配置好的UIView的子类。这让我们有更多复杂的视图和这些方便的枚举值一起用。
```Swift
enum ContentElement {
    case label(String)
    case button(String, () -> ())
    case image(UIImage)
    case custom(UIView)
}
```
第三，我们也可以给textView增加一个特定的情况。为了保持所有的回调代理被检验，我们可以先把他们单独拎出来。
```Swift
enum ContentElement {
    case label(String)
    case button(String, () -> ())
    case image(UIImage)
    case textView(String, didChange: (String) -> (), didBeginEditing: () -> ())
}
```
这很快变得不方便。然后我们可以在枚举中有一个单独的回调来管理这些事件，给每个事件用一个案例。
```Swift
enum TextViewEvent {
  case didChange(String)
  case didBeginEditing
  case openURL(URL)
}

enum ContentElement {
    case label(String)
    case button(String, () -> ())
    case image(UIImage)
    case textView(String, (TextViewEvent) -> ())
}
```
顺便说一下，我们也可以在其他回调的数目不定的情况使用这个方法，比如在一个view Controller中，像我们在Connecting View Controllers视频集中描述的那样。

### 自定义UIStoryboardSegue子类
下一个问题：是否在Connnecting View Controllers中使用App类好的？如果我们增加一些功能的话，这会变得复杂。一个可能方法是创建UIStoryboaedSegue的子类，就像Andy Matuschak的Refactor the Mega Controller讲解中说的。除了把这些所有逻辑放到App类中，他把很多逻辑放到了segues中。那样的话这就不在view Controller中了。

这个问题有两个部分。首先我们必须决定是否要使用故事版。在我们的案例中，我们决定不使用故事版，然后我们使用了变得比较臃肿的app类。这确实是一个问题，但是这应该也很容易分解成多个类。

第二个部分是我们从来没有在故事版中尝试自定义的segue子类。然而当我们使用故事版时这好像是一个敏感的方法。并没有一个正确的方式。我们的解决方案是多实践多创新，这对于我们的使用的案例确实很有用。

### 故事版，Nib还是纯代码
这是我们得到的一个关联的问题：我们是应该用故事版，Nib还是纯代码呢？我们无法回答。这些方式我们在过去的项目中都用过，都好用。就去选择适合你和你的项目的方式。这三种方式都需要你小心的保持你代码的可维护性并持续重构。

### 测试
有很多问题是关于测试的：我们应该测试什么？我们测试应该有多少？什么才是最好的方式。又一次这个我们无法回答。我们自己使用不同的方式。曾经在一个Rails客户端项目，我们使用BDD并且很好用。一旦我们交付了这个项目，另一个人可以直接开始工作而不需要多很多时间来转换代码基础。

我们也有一些视频集中使用了TDD的方式来开发。在那些特定的案例中，折让开发更快更简单。有很多其他部分的app，我们只能手动测试。在很多项目中，我们仅仅测试很少的一部分或者根本就不测试。这取决于你的项目。再一次，这可能没有一个绝对正确的方式。这取决于你工作的人事环境，你的项目目标和重要性。

你需要自己找到什么对你有用，什么没有用，测试对你的作用。我们做的和决定都不重要，因为每个人需要自己去发现。不同的人能力和工作的方式都不同。

当你考虑测试的时候，需要记住哪些能够帮助你。举个栗子，测试可以作为验证来帮助你代码正确，但这也可以帮助你设计你的代码。进一步讲，测试可以帮助你定义你的API。最终，测试可以作为一个文档。如果是多人协作的话，这就很有用了。
