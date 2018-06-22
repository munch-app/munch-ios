//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import Crashlytics

enum SearchService {
    case search(SearchQuery, Int, Int)
    case suggest(String, SearchQuery)
}

enum SearchFilterService {
    case count(SearchQuery)
    case price(SearchQuery)
}

enum SearchFilterAreaService {
    case head
    case get
}

extension SearchService: TargetType {
    var path: String {
        switch self {
        case let .search(_, from, size):
            return "/search?from=\(from)&size=\(size)"
        case .suggest:
            return "/search/suggest"
        }
    }
    var method: Moya.Method {
        return .post
    }
    var task: Task {
        switch self {
        case let .search(searchQuery, _, _):
            return .requestJSONEncodable(searchQuery)
        case let .suggest(text, searchQuery):
            return .requestJSONEncodable(SearchSearchRequest(text: text, searchQuery: searchQuery))
        }
    }

    struct SearchSearchRequest: Codable {
        var text: String
        var searchQuery: SearchQuery
    }
}

extension SearchFilterService: TargetType {
    var path: String {
        switch self {
        case .count:
            return "/search/filter/count"
        case .price:
            return "/search/filter/price"
        }
    }
    var method: Moya.Method {
        return .post
    }
    var task: Task {
        switch self {
        case .count(let searchQuery):
            return .requestJSONEncodable(searchQuery)
        case .price(let searchQuery):
            return .requestJSONEncodable(searchQuery)
        }
    }
}

extension SearchFilterAreaService: TargetType {
    var path: String {
        return "/search/filter/areas"
    }
    var method: Moya.Method {
        switch self {
        case .get:
            return .get
        case .head:
            return .head
        }
    }
    var task: Task {
        return .requestPlain
    }
}

extension SearchFilterAreaService {
    // TODO Store in Storage
    /*
            class LocationClient {
            private let decoder = JSONDecoder()
            private let storage: Storage?

            init() {
                do {
                    let diskConfig = DiskConfig(name: "api.discover.filter.locations")
                    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
                    self.storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
                } catch {
                    self.storage = nil
                    print(error)
                    Crashlytics.sharedInstance().recordError(error)
                }
            }

            func list(callback: @escaping (_ meta: MetaJSON, _ locations: [DeprecatedLocation], _ containers: [Container]) -> Void) {
                if let storage = storage {
                    try? storage.removeExpiredObjects()
                    let locations = try? storage.object(ofType: [DeprecatedLocation].self, forKey: "locations")
                    let containers = try? storage.object(ofType: [Container].self, forKey: "containers")
                    if let locations = locations, let containers = containers {
                        callback(.ok, locations, containers)
                        return
                    }
                }


                MunchApi.restful.get("/search/filter/locations/list") { meta, json in
                    guard meta.isOk() else {
                        callback(meta, [], [])
                        return
                    }

                    var locations = [DeprecatedLocation]()
                    var containers = [Container]()

                    if let array = json["data"].array {
                        for data in array {
                            let result = SearchClient.parseResult(result: data)
                            if let location = result as? DeprecatedLocation {
                                locations.append(location)
                            } else if let container = result as? Container {
                                containers.append(container)
                            }
                        }
                    }

                    if let storage = self.storage {
                        try? storage.setObject(locations, forKey: "locations", expiry: .seconds(60 * 60 * 25))
                        try? storage.setObject(containers, forKey: "containers", expiry: .seconds(60 * 60 * 25))
                    }
                    callback(meta, locations, containers)
                }
            }

            func search(text: String, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
                MunchApi.restful.get("/search/filter/locations/search", parameters: ["text": text]) { meta, json in
                    callback(meta, json["data"].compactMap({ SearchClient.parseResult(result: $0.1) }))
                }
            }
        }

    */
}

struct FilterPrice: Codable {
    var frequency: [String: Int]
    var percentiles: [Percentile]

    struct Percentile: Codable {
        var percent: Double
        var price: Double
    }
}

struct FilterCount: Codable {
    var count: Int
    var tags: [String: Int]
}

extension SearchQuery {
    init() {
        self.init(filter: SearchQuery.Filter(), sort: SearchQuery.Sort())

        if let tags = UserSetting.instance?.search.tags {
            for tag in tags {
                filter.tag.positives.insert(tag.capitalized)
            }
        }
    }
}

struct SearchQuery: Codable {
    var filter: Filter
    var sort: Sort

    struct Filter: Codable {
        var price = Price()
        var tag = Tag()
        var hour = Hour()
        var area: Area?

        struct Price: Codable {
            var name: String?
            var min: Double?
            var max: Double?
        }

        struct Tag: Codable {
            var positives = Set<String>()
        }

        struct Hour: Codable {
            var name: String?

            var day: String?
            var open: String?
            var close: String?
        }
    }

    // See MunchCore for the available sort methods
    struct Sort: Codable, Equatable {
        var type: String?
    }
}

extension SearchQuery: Equatable {
    static func ==(lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        return lhs.filter.price.name == rhs.filter.price.name &&
                lhs.filter.price.min == rhs.filter.price.min &&
                lhs.filter.price.max == rhs.filter.price.max &&

                lhs.filter.tag.positives == rhs.filter.tag.positives &&

                lhs.filter.hour.name == rhs.filter.hour.name &&
                lhs.filter.hour.day == rhs.filter.hour.day &&
                lhs.filter.hour.open == rhs.filter.hour.open &&
                lhs.filter.hour.close == rhs.filter.hour.close &&

                lhs.filter.area?.areaId == rhs.filter.area?.areaId &&

                lhs.sort.type == rhs.sort.type
    }
}