## 我们使用协议，ViewController容器和泛型等方法来从ViewController中分离出异步加载代码。

我们继续聊聊从网络加载数据。我们已经写了networking部分，所以今天我们将谈谈在UI中处理异步请求的方法。当我们从网络加载数据，我们总是面对这些问题：我们还没拿到数据，但是我们想要给用户显示活动或者进程指示器，就是菊花或者进度条。一旦数据到了，我们再配置这个视图。

我们从在一个独立ViewController应用这个模式开始。后面我们找找如何分离加载逻辑的不同的方法。

### Making View Controllers Asynchronous
首先我们建立一个简单的ViewController，EpisodeDetailViewController来简单显示一集的题目。在ViewDidLoad中，我们设定背景颜色和增加一个label。
```Swift
final class EpisodeDetailViewController: UIViewController {
    let titleLabel = UILabel()

    convenience init(episode: Episode) {
        self.init()
        titleLabel.text = episode.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        titleLabel.constrainEdges(toMarginOf: view)
    }
}
```
对于加载的部分，我们给ViewController增加另外的构造器。这个构造器使用Rsource<Episode>替代Episode。在S01E01章节中我们讨论了关于网络部分和如何处理source。在这个构造器中，我们使用sharedWebservice来从数据源中加载传入的数据。一旦网络层请求完成了，我们通过回调得到结果。如果我们不能从结果中得到dpisode我们仅仅立即返回，并且我们使用guard语句用于早点退出。在guard后面，我们知道我们有了Episode对象并更新label。因我们引用了self，需要使用weak来避免循环引用。最终当数据返回的时候并没有显示在屏幕上。最终，我们需要调用一下父类的init方法。
```Swift
convenience init(resource: Resource<Episode>) {
    self.init()
    sharedWebservice.load(resource) { [weak self] result in
        guard let value = result.value else { return } // TODO loading error
        self?.titleLabel.text = value.title
    }
}
```
使用构造器，我们可以更新调用方法。而不是处理一个episode我们有Resource提供给ViewController.

我们仍然没有一个活动指示器。我们增加一个spinner属性用来给ViewController存储UIActivityIndicatorView.我们在发网络请求前发起spinner。一旦网络其你去完成了，停止spinner，无论网络请求是否成功。另外，我们用self？引用spinner，来避免循环引用。
```Swift
convenience init(resource: Resource<Episode>) {
    self.init()
    spinner.startAnimating()
    sharedWebservice.load(resource) { [weak self] result in
        self?.spinner.stopAnimating()
        guard let value = result.value else { return } // TODO loading error
        self?.titleLabel.text = value.title
    }
}
```
我们在ViewDidLoad中配置spinner。我们把hidesWhenStopped设置为true，关闭resizing mask转换，并且藏家一个spinner。最终，我们把他放到中间，使用一个我们的auto layout extension。

```Swift
spinner.hidesWhenStopped = true
spinner.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(spinner)
spinner.center(inView: view)
```
显示spinner，我们仍然需要用一个特定的style来初始化，目前我们先简单用.Gray来初始化。
```Swift
let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
```
有很多样板代码来创建和配置activity indicator，并且我们必须在很多不同的ViewController里面重复。既然如此，当然是把这段逻辑分离出ViewController中比较好。这样做的话会节约很多工作，也使得ViewController更简单。

### Creating the Loading Protocol
首先我们尝试的方法时创建一个协议，并且把这些代码拉入到协议的扩展中。这个方法和苹果公司在WWDC2015session中面向协议编程给出了demo。我们开始增加一个Loading协议，定义spinner为一个只读属性。我们也给protocol增加一个load方法，执行实际的网络请求和开始于停止spinner。这个方法把resource当做参数。因为我们不能更加明确Resource的泛型。我们给协议增加一个叫做ResourceType的关联类型，这样可以处理任何类型。
```Swift
protocol Loading {
    associatedtype ResourceType
    var spinner: UIActivityIndicatorView { get }
    func load(resource: Resource<ResourceType>)
}
```
因为我们想提供load方法，我们创建一个协议扩展。实际上我们在协议扩展中申明load方法就够了，因为我们不想让这个方法被遵循Loading协议的类复写。
```Swift
protocol Loading {
    associatedtype ResourceType
    var spinner: UIActivityIndicatorView { get }
}

extension Loading {
    func load(resource: Resource<ResourceType>) {
        // TODO
    }
}
```
现在我们就移动写在ViewController里面的代码到协议中的load方法中。这个方法仍然执行一样的任务：开始转菊花，从web service中加载数据，和停止转菊花。为了使这些代码运作，我们约束这些协议给UIViewController的实例。
```Swift
extension Loading where Self: UIViewController {
    func load(resource: Resource<ResourceType>) {
        spinner.startAnimating()
        sharedWebservice.load(resource) { [weak self] result in
            self?.spinner.stopAnimating()
            guard let value = result.value else { return } // TODO loading error
            // TODO configure views
        }
    }
}
```
在我们的协议扩展中，我们不知道在我们从网络返回后怎么配置view。因此我们需要代理这个任务回给ViewController本身。为此我们给协议增加一个configure方法需要一个ResourceType类型的值。一旦网络数据返回我们调用configure方法。
```Swift
protocol Loading {
    // ...
    func configure(value: ResourceType)
}

extension Loading where Self: UIViewController {
    func load(resource: Resource<ResourceType>) {
        spinner.startAnimating()
        sharedWebservice.load(resource) { [weak self] result in
            self?.spinner.stopAnimating()
            guard let value = result.value else { return } // TODO loading error
            self?.configure(value)
        }
    }
}
```
现在我们可以使ViewController遵循Loading。spinner属性已经存在，所以我们就必须实现configure方法，把label的text设置成episode的标题。
```Swift
final class EpisodeDetailViewController: UIViewController, Loading {
    // ...
    func configure(value: Episode) {
        titleLabel.text = value.title
    }
    // ...
}
```
我们可以在构造器中调用load方法
```Swift
final class EpisodeDetailViewController: UIViewController, Loading {
    convenience init(resource: Resource<Episode>) {
        self.init()
        load(resource)
    }
    // ...
}
```
我们可以分离这些代码并且在viewDidLoad中建立spinner，但是我们将先将就一下。


这个已经改进了很多，因为我们从ViewController中移除了大量代码。然而这并不是完美的解决方案。一个缺点是我们仅仅隐藏了之前在ViewController中的代码到协议中。ViewController仍和这些代码紧密耦合。举个栗子，如果没有网络栈，我们无法实例化EpisodeDetailViewController。这让测试变得没必要的复杂。

### Using Container View Controllers
我们试试一个不同的方法，使用container View Controller来分离显示loading activity和显示数据的部分。Container View Controller会发起网络请求，并且一旦数据返回，我们可以增加final View Controller作为子Controller。


第一步是创建一个叫做LoadingViewController的UIViewController.构造器使用任何的resource，所以我们必须给构造器增加一个泛型参数。第二参数是build方法，用于传入网络请求的返回结果并返回一个View Controller。
```Swift
final class LoadingViewController: UIViewController {
    init<A>(resource: Resource<A>, build: (A) -> UIViewController) {
        // TODO
    }
}
```
add方法征程的增加一个child View Controller。首先我们调用addChildViewController并且增加他的view为subview。然后我们添加一些约束。最终我们调用Child View Controller的didMoveToParentViewController。
```Swift
func add(content content: UIViewController) {
    addChildViewController(content)
    view.addSubview(content.view)
    content.view.translatesAutoresizingMaskIntoConstraints = false
    content.view.constrainEdges(toMarginOf: view)
    content.didMoveToParentViewController(self)
}
```
为了使LoadingViewController编译，我们必须增加相应的必要构造器。Xcode可以使用"fix all in scope"快捷键修复这些问题。

增加spinner到view层级上，我们从EpisodeDetailViewController中的viewDidLoad方法中拷贝代码。
```Swift
override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .whiteColor()
    spinner.hidesWhenStopped = true
    spinner.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(spinner)
    spinner.center(inView: view)
}
```
在LoadingViewController中，我们现在可以清理EpisodeDetailViewcontroller并且移除所有没有用到的代码。实际上我们仅仅把他转换成原始的状态。


为了试试新的LoadingViewController，我们用episode resource来完成实例化。然后我们从编译方法中返回EpisodeDetailViewController的一个实例。
```Swift
let episodesVC = LoadingViewController(resource: episodeResource, build: { episode in
    return EpisodeDetailViewController(episode: episode)
})
```
另一个提升是直接使用EpisodeDetailViewController.init作为编译方法。通过直接调用构造器，我们不需要匿名方法。
```Swift
let episodesVC = LoadingViewController(resource: episodeResource, build: EpisodeDetailViewController.init)
```
我们喜欢这个方式是因为EpisodeDetailViewController现在又变得很简单。也是同步的，因此在分离测试中也很简单。


然而我们仍然改进LoadingViewController通过移除其对shared web service的依赖。不传递一个resource，我们可以传进一个实际执行加载数据的load方法。一旦这个回调被调用了，我们可以像之前一样进行和build方法。load方法参数是一个单参数方法，没有返回类型。这个参数是一个需要A类型的Result方法。不再调用sharedWebservice.load,现在我们可以调用load方法，其他的保持不变。
```Swift
init<A>(load: ((Result<A>) -> ()) -> (), build: (A) -> UIViewController) {
    super.init(nibName: nil, bundle: nil)
    spinner.startAnimating()
    load() { [weak self] result in
        self?.spinner.stopAnimating()
        guard let value = result.value else { return } // TODO loading error
        let viewController = build(value)
        self?.add(content: viewController)
    }
}
```
现在我们移动call到shared web service中去，在我们实例化LoadingViewController的地方。实现load方法很直接，我们传入callback然后用episode resource调用shared web service作为完成的回调。
```Swift
let sharedWebservice = Webservice()

let episodesVC = LoadingViewController(load: { callback in
    sharedWebservice.load(episodeResource, completion: callback)
}, build: EpisodeDetailViewController.init)
```
如果我们想要实例化LOadingViewController用Resource来加载数据，为了避免代码重复，我们可以增加一个便利构造器在LOadingViewcontroller的扩展中。然而，loading View
 Controller不再依赖于Web Service这样好多了。loading View Controller不再有任何依赖，并且EpisodeDetailViewController被大幅删减，使得测试非常容易。
 
### Pros and Cons
使用协议和使用container View Controller两者都各自有优缺点。使用container View Controller问题在于子View Controller有的时候不能和UIKit很好的配合。举个列子，如果你把LoadingViewController放进navigation栈里，这个可能会影响UIKit的布局调整和扩展边缘。撇开这些问题，这个方法再开发中还是很有用的。另外，有时候我们使用这个方法，仅仅作为临时的方法。在这些事例中，这很好的使View Controlller变得即刻异步。在这些地方，我们使用child View Controller，这个方法也可以在最终的代码中很好的运行。


child View Controller的另外一个问题是Navigation Items无法使用。因此你必须写额外的代码。无论如何，在你不改变View Controllers的代码情况下LoadingViewController变得很顺手。举个栗子，我们用它包裹AVPlayerViewController.


在这些实例中，child View Controllers并不能很好的运行，你可以分离使用另外的方法分离异步加载数据这个通用模式。举个栗子，我们刚刚在使用协议之前的栗子。协议方法也有更加轻量的优势，因为他并在View 层级中添加另外的图层。


另外一个实例我们在我们的项目中使用了LoadingViewController给table View
 Controller作一个暂时的解决方案,在我们实现下拉刷新之前。一旦我们使用了下拉刷新，我们简单把这个包裹溢出了。这是在你的项目开发中一个很好的工具。
