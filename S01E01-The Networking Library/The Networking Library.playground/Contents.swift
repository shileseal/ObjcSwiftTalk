//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

typealias JSONDictionary = [String: Any]

let url = URL(string: "http://localhost:8000/episodes.json")!

struct Episode {
    var id: String
    var title: String
}

extension Episode {
    init?(dictionary: JSONDictionary) {
        guard let id = dictionary["id"] as? String,
            let title = dictionary["title"] as? String else {
            return nil
        }
        self.id = id
        self.title = title
    }
}

struct Media {}

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

extension Episode {
    static let all = Resource<[Episode]>(url: url, parseJSON: { json in
        guard let dictionaries = json as? [JSONDictionary] else { return nil }
        return dictionaries.flatMap(Episode.init)
    })
}

final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        URLSession.shared.dataTask(with: resource.url) { (data, _, _) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data))
            //            let result = data.flatMap(resource.parse)
            //            completion(result)
            //            guard let data = data else {
            //                completion(nil)
            //                return
            //            }
            //            completion(resource.parse(data))
            //            if let data = data {
            //                completion(resource.parse(data))
            //            } else {
            //                completion(nil)
            //            }
            }.resume()
    }
    //    func loadEpisodes(completion: ([Episode]?) -> ()) {
    //        //TODO
    //    }
    //    func loadMedia(episode: Episode, completion: (Media?) -> ()) {
    //        //TODO
    //    }
}

PlaygroundPage.current.needsIndefiniteExecution = true

Webservice().load(resource: Episode.all) { (result) in
    print(result ?? "")
}


//extension Sequence {
//    public func failingFlatMap<T>(transform: (Self.Iterator.Element) throws -> T?) rethrows -> [T]? {
//        var result: [T] = []
//        for element in self {
//            guard let transformed = try transform(element) else { return nil }
//            result.append(transformed)
//        }
//        return result
//    }
//}




