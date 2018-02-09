//: Playground - noun: a place where people can play

import UIKit

let url = URL(string: "http://localhost/episodes.json")

typealias JSONDictionary = [String: Any]

struct Episode {
    var id: String
    var title: String
}

extension Episode {
    init?(dictionary: JSONDictionary) {
        guard let id = dictionary["id"] as? String,
        let title = dictionary["title"] as? String else { return nil }
        self.id = id
        self.title = title
    }
}

struct Resource<A> {
    let url: URL
    let parse: (Any) -> A?
}

extension Resource {
    init(url: URL, parseJSON: @escaping (Any) -> A?) {
        self.url = url
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data as! Data, options: [])
            return json.flatMap(parseJSON)
        }
    }
}

let episodeResource = Resource<Episode>(url: url) { (any) in
    (any as? JSONDictionary).flatMap(Episode.init)
}

protocol Loading {
    associatedtype ResourceType
    var spinner: UIActivityIndicatorView { get }
    func configure(value: ResourceType)
}

extension Loading where Self: UIViewController {
    func load(resource: Resource<ResourceType>) {
        spinner.startAnimation()
        sharedWebservice.load(resource) { [weak self] result in
            self?.spinner.stopAnimating()
            guard let value = result.value else { return }
            self.configure(value)
        }
    }
}

final class EpisodeDetailViewController: UIViewController {
    
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let titleLabel = UILabel()
    
    
    convenience init(episode: Episode) {
        self.init()
        load(resource)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        spinner.hidesWhenStopped = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        spinner.center(inView: self.view)
    }
    
    func configure(value: EpisodeDetailViewController.ResourceType) {
        titleLabel.text = value.title
    }
}

final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        URLSession.shared.dataTask(with: resource.url) { (data, _, _) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data))
        }.resume()
    }
}

final class LoadingViewController: UIViewController {
    
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    init<A>(load: ((Resource<A>) -> ()) -> (), build: (A) -> UIViewController) {
        super.init(nibName: nil, bundle: nil)
        spinner.startAnimating()
        load() { [weak self] result in
            self?.spinner.stopAnimating()
            guard let value = result.value else { return }
            let viewController = build(value)
            self?.add(content: viewController)
        }
    }
    
    private func add(content content: UIViewController) {
        addChildViewController(content)
        view.addSubview(content.view)
        content.view.translatesAutoresizingMaskIntoConstraints = false
        content.view.constrainEdges(toMarginOf: self.view)
        content.didMove(toParentViewController: self)
    }
}

let sharedWebservice = Webservice()
let episodesVC = LoadingViewController(load: { (callback) in
    sharedWebservice.load(resource: episodeResource, completion: callback)
}, build: EpisodeDetailViewController.init)

extension UIView {
    public func constrainEqual(_ attribute: NSLayoutAttribute, to: AnyObject, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        constrainEqual(attribute, to: to, toAttribute: attribute, multiplier: multiplier, constant: constant)
    }
    public func constrainEqual(_ attribute: NSLayoutAttribute, to: AnyObject, toAttribute: NSLayoutAttribute, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        NSLayoutConstraint.activate([NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: to, attribute: toAttribute, multiplier: multiplier, constant: constant)])
    }
    
    public func constrainEdges(toMarginOf view: UIView) {
        constrainEqual(.top, to: view, toAttribute: .topMargin)
        constrainEqual(.leading, to: view, toAttribute: .leadingMargin)
        constrainEqual(.trailing, to: view, toAttribute: .trailingMargin)
        constrainEqual(.bottom, to: view, toAttribute: .bottomMargin)
    }
    
    public func center(inView view: UIView) {
        centerXAnchor.constraint(equalTo: view.centerXAnchor)
        centerYAnchor.constraint(equalTo: view.centerYAnchor)
    }
}

//extension NSLayoutAnchor {
//    public func constrainEqual(anchor: NSLayoutAnchor, constant: CGFloat = 0) {
//        let layoutConstraint: NSLayoutConstraint = constraint(equalTo: anchor, constant: constant)
//        layoutConstraint.isActive = true
//    }
//}

