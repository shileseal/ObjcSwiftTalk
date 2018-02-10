## 我们使用申明式的方式使用枚举定义UI元素来创建一个抽象视图栈。

我们经常使用栈来存储视图，特别是在原型模式中，因为这样很方便地把视图堆到一起。然而，因我们使用代码创建视图（可以看一下S01E05那一集将为什么我们要用代码创建）我们需要写很多代码来建立栈视图。因此通过抽象化来简化这个过程是有意义的。

### 在代码中使用UIStackView
我们从创建一个简单的View Controller开始，这也是在viewDidLoad中传统的建立Stack View的方式。
```Swift
final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .Vertical
        stack.spacing = 10
        view.addSubview(stack)

        stack.constrainEqual(.Width, to: view)
        stack.center(in: view)

        let image = UIImageView(image: [#Image(imageLiteral: "objc-logo-white.png")#])
        stack.addArrangedSubview(image)

        let text1 = UILabel()
        text1.numberOfLines = 0
        text1.text = "To use the Swift Talk app please login as a subscriber"
        stack.addArrangedSubview(text1)

        let button = UIButton(type: .System)
        button.setTitle("Login with GitHub", forState: .Normal)
        stack.addArrangedSubview(button)

        let text2 = UILabel()
        text2.numberOfLines = 0
        text2.text = "If you're not registered yet, please visit http://objc.io for more information"
        stack.addArrangedSubview(text2)
    }
}
```
对于这个图片，我们使用playground's image literals，这个能很方便的从playground's资源中加载图片。这个button还没有链接到action，我们一会做这个。


我们在playground中实例化这个View Controller并且预览这个视图。
```Swift
let vc = ViewController()
vc.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
vc.view
```
![s01e07-stackview.png](http://upload-images.jianshu.io/upload_images/1645479-5c66bccbd022c851.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 用枚举描述视图
像这样使用栈视图是很方便的，因为这可以替你处理布局，不过还有很多代码要写。这样在创建视图的时候还有很多重复，比如设置UILabel上的numberOfLines属性，尤其是我们app中有很多label的配置是相似的。


一个实现抽象化栈视图的方法是给想要显示的不同的内容类型定义一个枚举。

```Swift
enum ContentElement {
    case label(String)
    case button(String) // TODO: Add an action
    case image(UIImage)
}
```
现在我们可以使用ContentElements来创建我们想要显示的描述，并且一会儿把他们转换成view。在我们这么做之前，我们需要记住button需要一个方式和一个action关联。最后我们来看这个。


给不同的ContentElement的不同的元素创建视图，我们用计算属性UIView类型的view来增加一个扩展。我们通过对self的判断来处理不同的情况。对于.label我们返回一个UILabel.我们可以从之前在viewDidLoad中复制一下代码。我们就必须要改变text1名字为label并且使用给.label的关联值替换写死的字符串。我们用同样的方式创建另外两种枚举值.button和.image。
```Swift 
extension ContentElement {
    var view: UIView {
        switch self {
        case .label(let text):
            let label = UILabel()
            label.numberOfLines = 0
            label.text = text
            return label
        case .button(let title):
            let button = UIButton(type: .System)
            button.setTitle(title, forState: .Normal)
            return button
        case .image(let image):
            return UIImageView(image: image)
        }
    }
}
```
让我们用ContentElement来创建我们要添加到Stack View上面的视图。
```Swift
let image = ContentElement.image([#Image(imageLiteral: "objc-logo-white.png")#]).view
stack.addArrangedSubview(image)

let text1 = ContentElement.label("To use the Swift Talk app please login as a subscriber").view
stack.addArrangedSubview(text1)

let button = ContentElement.button("Login with GitHub").view
stack.addArrangedSubview(button)

let text2 = ContentElement.label("If you're not registered yet, please visit http://objc.io for more information").view
stack.addArrangedSubview(text2)
```
在这个image枚举中，代码并没有得到很大的改进。尽管label和button的步骤是好些了。总体来说，这是一个谦虚的进步，但是我们在ContentElements上我们可以做很多。

### 从枚举创建栈视图
下一步，我们给UIStackView增加构造器。这个构造器使用ContetnElement数组作为参数，并且使用遍历把视图添加到栈视图中。不使用子类化，我们仅仅能给已有的类添加一个便利构造器。
```Swift
extension UIStackView {
    convenience init(elements: [ContentElement]) {
        self.init()
        for element in elements {
            addArrangedSubview(element.view)
        }
    }
}
```
现在我们可以删除viewDidLoad中addArrangeSubview的调用并且把内容元素传给新的构造器。
```Swift
let image = ContentElement.image([#Image(imageLiteral: "objc-logo-white.png")#])
let text1 = ContentElement.label("To use the Swift Talk app please login as a subscriber")
let button = ContentElement.button("Login with GitHub")
let text2 = ContentElement.label("If you're not registered yet, please visit http://objc.io for more information")

let stack = UIStackView(elements: [image, text1, button, text2])
```
如果我们把元素数据偶读提取出来并且指定变量的一个类型。我们可以把所有的ContentElement的.前缀去掉。
```Swift
let elements: [ContentElement] = [
    .image([#Image(imageLiteral: "objc-logo-white.png")#]),
    .label("To use the Swift Talk app please login as a subscriber"),
    .button("Login with GitHub"),
    .label("If you're not registered yet, please visit http://objc.io for more information")
]

let stack = UIStackView(elements: elements)
```
这是一个描述我们的接口显示申明的方式，那样的话可读性很高。另外我们可以把stack View的配置移到构造器里。因为在我们的项目中多数的栈视图的配置是相似的。这样就可以删掉viewDidLoad方法中的一堆代码。
```Swift
extension UIStackView {
    convenience init(elements: [ContentElement]) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        axis = .Vertical
        spacing = 10

        for element in elements {
            addArrangedSubview(element.view)
        }
    }
}
```
### 创建一个栈视图控制器
为了移除更多代码，我们可以用content elementes数组来初始化一整个视图控制器。这样的话，我们避免了重复我们在view Controller的viewDidLoad方法中必要的步骤。


我买的StackViewController类有一个使用[ContentElement]参数的自定义构造器，就像刚才在UIStack中的便利构造器一样。这边我们调用指定的父类构造器，并把Content Elements存到一个属性里。
```Swift
final class StackViewController: UIViewController {
    let elements: [ContentElement]

    init(elements: [ContentElement]) {
        self.elements = elements
        super.init(nibName: nil, bundle: nil)
    }
    // ...
}
```
为了建立这个栈视图，我们可以从我们已经实现了的viewDidLoad方法可似乎。我们就必须剪切elements数组的定义出来。我们一会儿把这个粘贴到我们实例化stack View Controller的地方。最后我们也需要增加要求构造器的默认实现才能开始编译。
```Swift
final class StackViewController: UIViewController {
    let elements: [ContentElement]

    init(elements: [ContentElement]) {
        self.elements = elements
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()

        let stack = UIStackView(elements: elements)
        view.addSubview(stack)
        stack.constrainEqual(.Width, to: view)
        stack.center(in: view)
    }
}
```
为了测试StackViewController这个类，我们把elements数组粘贴到我们实例化view Controller的地方。
```Swift
let elements: [ContentElement] = [
    .image([#Image(imageLiteral: "objc-logo-white.png")#]),
    .label("To use the Swift Talk app please login as a subscriber"),
    .button("Login with GitHub", {
        print("Button tapped")
    }),
    .label("If you're not registered yet, please visit http://objc.io for more information")
]

let vc = StackViewController(elements: elements)
```
结果视图还没有动，但是创建他的代码简短且明确。StackViewController的抽象化让我们可以快速的用原型创建出一个屏幕内容。这个对于与其他一起参与的人沟通来说很有用。我们一会儿继续优化。

### 一个回调的按钮
我们还必须写一下ContentElement.button。到这它还什么都没做，而且我们没有指定action的方式。简单的部分是给枚举值增加一个回调，这个回调将在用户点击按钮的时候执行。
```Swift
enum ContentElement {
    // ...
    case button(String, () -> ())
}
```
然而让回调和UIButton关联是不确定的。我们可以试试子类化UIButton并且在那里引用闭包，但是那样也不行。举个栗子，构造器的文档告诉我们UIButton(type:)不能返回一个自定义子类的实例，所以这个办法有点困难。


另一个方法是简单的包装UIButton来接收.TouchUpInside事件并且调用回调。我们调用继承自UIView的CallbackButton类。构造器定义了button的文字和回调。他们用属性来存储回调，建立button实例作为一个子视图，并且给button增加约束。
```Swift
final class CallbackButton: UIView {
    let onTap: () -> ()
    let button: UIButton

    init(title: String, onTap: () -> ()) {
        self.onTap = onTap
        self.button = UIButton(type: .System)
        super.init(frame: .zero)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.constrainEdges(to: self)
        button.setTitle(title, forState: .Normal)
        button.addTarget(self, action: #selector(tapped), forControlEvents: .TouchUpInside)
    }
    // ...
}
```
现在我们可以增加tapped方法最终调用我们传进构造器的回调。
```Swift
func tapped(sender: AnyObject) {
    onTap()
}
```
最后我们再一次的添加要求构造器的默认实现。完整的CallbackButton类如下：
```Swift
final class CallbackButton: UIView {
    let onTap: () -> ()
    let button: UIButton

    init(title: String, onTap: () -> ()) {
        self.onTap = onTap
        self.button = UIButton(type: .System)
        super.init(frame: .zero)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.constrainEdges(to: self)
        button.setTitle(title, forState: .Normal)
        button.addTarget(self, action: #selector(tapped), forControlEvents: .TouchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tapped(sender: AnyObject) {
        onTap()
    }
}
```
CallbackButton是一种支撑，因为我们必须要给我们的按钮回调关联UIKit的target/action机制。但是至少成功了，而且安全。


现在我们就必须在ContentElement的view属性中使用CallbackButton。我们改变.button枚举像下面这样：
```Swift
extension ContentElement {
    var view: UIView {
        switch self {
        // ...
        case .button(let title, let callback):
            return CallbackButton(title: title, onTap: callback)
        }
    }
}
```
我们成功的用声明式的方式来构建我们的栈视图，我们发现这是个很有用的原型工具。


我们可以扩展我们的实现在后面很多明显的方式。举个栗子，增加一个自顶一个枚举值来显示UIView随意的实例。增加一个异步的枚举值也很有意思。这让我们可以从网络加载数据，并且一旦数据到了可以替换视图。另一方面，增加越来越多的枚举值会使得这种简单抽象变得逐渐复杂。所以我们就止步于在所有UIKit中实现这些。毕竟总归要按需求编程。

另一个有趣的使用抽象化的案例，是可以用我们收到的数据构建视图层级，比如从服务器上。我们可以简单的把JSON字典转换成ContentElement并且创建StackViewController出来。


总是有很多有趣的可能，但是即使实在这个简单的示例中，抽象化也帮助我们快速迭代和代码整洁。
