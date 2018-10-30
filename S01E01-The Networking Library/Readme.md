## 我们使用Swift泛型和结构体来构建一个简单的高可测试性的网络层。

我们聊聊Swift Talk App的网络层。这是一个好例子因为我们设计网络层的时候跟oc的项目不一样。尤其是我们创建了Websevice的类和一些方法来执行请求到不同的终端。这些方法通过闭包来返回数据。举个栗子，我们有loadEpisodes方法来执行请求，解析结果，实例化Episode对象，返回[Episode]这样的数组。同样的我们也写了loadMedia方法。

```Swift
final class Webservice {
    func loadEpisodes(completion: ([Episode]?) -> ()) {
        // TODO
    }

    func loadMedia(episode: Episode, completion: (Media?) -> ()) {
        // TODO
    }
}
```
在oc中这种模式

### 优势
自傲与返回值有正确的类型。举个栗子，我们可以得到[episode]，而并不仅是id类型，因为这是从网络加载的方法。

### 劣势
每个方法都执行了复杂的任务：执行秦秋，解析数据，实例化成model对象，最终通过callback返回数据。流程长了，很多地方都容易出错，所以难以测试。并且这些方法都是异步的，更难以测试。而且我们需要建立一个网络栈来mock，这使得测试更加复杂。在Swift中，有很多其他模式我们可以用来是这个变得简单。

## The Resource Struct
我们创建返回类型是泛型的Resource结构体，Resource有两个属性，到终端的URL和parse数据到结果的方法。
```Swift
struct Resource<A> {
    let url: NSURL
    let parse: NSData -> A?
}
```
因为解析过程可能失败，所以parse方法返回类型是可选类型。不用可选类型的话，为了传递更多错误信息，我们可以使用Result类型或者用throws。补充说，如果我们想要处理JSON，解析方法可以使用AnyObject类型来替代Data类型。然而使用了AnyObject类型我们就只能使用Resource来解析JSON而不能用于其他数据，比如images。


创建episodesResource.这是一个简单的resource返回Data。
```Swift
let episodesResource = Resource<NSData>(url: url, parse: { data in
    return data
})
```
最终这个resource需要有返回类型是[Episode].我们一会儿会重构parse方法，用几个步骤把返回值从Data改为[Episode]。

## The Webservice Class
为了从网络层加载resource，我们创建WebServiece类和一个方法load。这个方法时泛型的并且把resource作为他的第一参数。第二个参数是完成闭包，用A？因为网络请求可能失败和出错。在load方法中我们使用URLSession.shared来执行网络请求。我们用url创建data task，用来获取resource。这个resource绑定了所有我们需要来执行请求的信息。现在里面只有url，不过以后会有更多的属性。在data task的完成闭包中，我们获取数据作为第一个参数，但是我们我们将忽略其他两个参数。最后，data task别忘了使用resume().
```Swift
final class Webservice {
    func load<A>(resource: Resource<A>, completion: (A?) -> ()) {
        NSURLSession.sharedSession().dataTaskWithURL(resource.url) { data, _, _ in
            if let data = data {
                completion(resource.parse(data))
            } else {
                completion(nil)
            }
        }.resume()
    }
}
```

为了调用闭包，我们必须通过parse方法把data转成resource的结果类型。由于data是可选类型，我们使用可选链。如果data是nil，我们返回nil，如果不是，我们用parse方法的结果给完成闭包调用。

因为用的是playgroud，我们必须让他无限执行。否则代码在main queue完成之后就停止了。
```Swift
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
```

我们创建一个Webservice实例并调用load方法和spisodesResource, 在闭包中我们打印结果。

```Swift
Webservice().load(episodesResource) { result in
    print(result)
}
```
在控制台我们看到我们得到的原始2进制的值。我们继续重构load方法，我们不喜欢调用两次competion，我们尝试使用guard let。然而，我们还是需要调用两次completion，并且我们总是需要增加一个额外的返回语句。

```Swift
final class Webservice {
    func load<A>(resource: Resource<A>, completion: (A?) -> ()) {
        NSURLSession.sharedSession().dataTaskWithURL(resource.url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data))
        }.resume()
    }
}
```
另外一个方法是使用flatMap。首先我们可以尝试map，但是map给我们一个A？？并不是我们想要找的A？。使用flatMap可以移除重复的？？。
```Swift
final class Webservice {
    func load<A>(resource: Resource<A>, completion: (A?) -> ()) {
        NSURLSession.sharedSession().dataTaskWithURL(resource.url) { data, _, _ in
            let result = data.flatMap(resource.parse)
            completion(result)
        }.resume()
    }
}
```
## Parsing JSON
下一个步骤，我们会改变episodesResource为了把Data解析成JSON对象。为此我们使用苹果自带的JSON解析。因为JSON解析是一个要抛异常的操作，所以我们使用try?
```Swift
let episodesResource = Resource<AnyObject>(url: url, parse: { data in
    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    return json
})
```
在侧边栏中，我们看到二进制数据被解析了。是一个字典的数组，所以我们进一步明确返回类型。一个JSON字典包括了String作为Keys和AnyObject作为values。如果我们需要一个JSONDictionary数组，我们需要类型转换。
```Swift
typealias JSONDictionary = [String: AnyObject]

let episodesResource = Resource<[JSONDictionary]>(url: url, parse: { data in
    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    return json as? [JSONDictionary]
})
```
下一步是返回Episodes数组，我们需要把每个JSON字典转换成Episode对象。我们可以在Episode构造器中传入Dictionary。在哦我们写构造器之前，我们先给Episode增加一些属性id和title，都是String类型的。现实项目中会有更多属性。
```Swift
struct Episode {
    let id: String
    let title: String
    // ...
}
```
现在我们可以重构episodesResource来返回Episodes数组。首先我们check一下JSON Dictionaries。否则我们立即返回nil。为了把dictionaries转换成episodes，我们可以使用map和可以失败的Episode.init作为我们的转换方法。然而构造器返回一个可选类型，所以map的结果是[Episode?].但是我们不希望有nil在这里，返回的结果需要是[Episode].再一次我们使用flatmap来解决这个问题。

在我们的项目中，我们使用了不同版本的flatMap。flatMap会默认忽略不能被解析的dictionaries，并且我们希望彻底失败防止dictionaries是无效的。不忽略这些失效的dictionaries是一个领域性的决定。
```Swift
extension SequenceType {
    public func failingFlatMap<T>(@noescape transform: (Self.Generator.Element) throws -> T?) rethrows -> [T]? {
        var result: [T] = []
        for element in self {
            guard let transformed = try transform(element) else { return nil }
            result.append(transformed)
        }
        return result
    }
}
```
我们可以重构我们的解析方法来解决两次返回问题。首先我们尝试使用guard，但是这没有解决问题。然而guard允许我们去除一级nesting，并且之前的退出更清晰了。
```Swift
let episodesResource = Resource<[Episode]>(url: url, parse: { data in
    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    guard let dictionaries = json as? [JSONDictionary] else { return nil }
    return dictionaries.flatMap(Episode.init)
})
```
我们可以去除两次return通过在dictionaries中使用可选链。
```Swift
let episodesResource = Resource<[Episode]>(url: url, parse: { data in
    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    let dictionaries = json as? [JSONDictionary]
    return dictionaries?.flatMap(Episode.init)
})
```
这种写法刚开始难以理解。我们有一个可选dictionaries，并且我们使用可选链来使用可失败的构造器来调用flatMap。这种情况下，我们可能可以寻找guard的版本。因为更加清晰。然而你可以为其他解决方案制造参数。

## JSON Resources
一旦我们创建了更多resource，需要在每个resource中重复JSON解析。为了解决这个重复，我们创建两种不同的resource。然而，我们能用另一种构造器来扩展已经存在的resource。这个构造器依然使用URL，但是解析函数是AnyObject -> A?, 而不是Data -> A?。我们wrap这个解析函数在另一个函数Data -> A?并且移除JSON解析从episodesResource到wrapper上。因为被解析的JSON是可选的，我们能用flatMap来调用parseJSON。

```Swift
extension Resource {
    init(url: NSURL, parseJSON: AnyObject -> A?) {
        self.url = url
        self.parse = { data in
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
            return json.flatMap(parseJSON)
        }
    }
}
```
现在我们可以改变episodesResource成使用新的构造器。
```Swift
let episodesResource = Resource<[Episode]>(url: url, parseJSON: { json in
    guard let dictionaries = json as? [JSONDictionary] else { return nil }
    return dictionaries.flatMap(Episode.init)
})
```
## Naming the Resources
另外一个我们不喜欢的是episodesResource是在全局namespace里面。我们也不喜欢这样的命名。我们可以移动episodesResource到一个Episode上的扩展。我们可以重命名为allEpisodesResource，一个描述的和冗长的名字。然而我们不实际喜欢。看看这个类型，很明显这个属于Episode。从这个类型看，显然这是一个resource，所以我们为什么不就叫做all？在调用的时候就明显多了。
```Swift
Webservice().load(Episode.all) { result in
    print(result)
}
```
看看这个调用写法，确实是个好主意。然而在开始的时候我们认为是危险的名字，因为你可能会和一个collection相混淆。我们不认为这是个问题，以为你当你误以为是colleciton 的时候，会立即失败。

在Episode的扩展中，我们也可以添加依赖episode属性的其他resources，举个栗子，一个mediaresource从一个特定的espisode获取的。在media resource中，我们可以使用string 添写来构建一个URL
```Swift
extension Episode {
    var media: Resource<Media> {
        let url = NSURL(string: "http://localhost:8000/episodes/\(id).json")!
        // TODO Return the resource ...
    }
}
```
如果我们需要更多Episode无法提供的参数。我们可以改变resource属性给一个方法或者直接把他传递进去。

我们喜欢这个网络方法因为所有的代码都是同步的。这是简单的，易于测试，并且我们不用建立一个网络栈或者其他东西来做测试。这个唯一异步的代码是WebService.load方法。这个架构是一个好的例子使用Swift。Swift的泛型和结构使得容易这么设计。同样的设计并不能在OC上有用，and it would have felt out of place。

后面的某集，我们增加POST方法。
