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

final class LoadingViewController: UIViewController {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
}
