//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift
import RealmSwift

import Crashlytics

enum SearchScreen: String {
    case search
    case home
    case location
    case award
    case collection
}

enum SearchService {
    case search(SearchQuery, SearchScreen, Int)

    case qid(String)

    case named(String)
}

enum SuggestService {
    case suggest(String, SearchQuery)
}

enum SearchFilterService {
    case count(SearchQuery)
    case areas
    case betweenSearch(String)
}

extension SearchService: TargetType {
    var path: String {
        switch self {
        case .search:
            return "/search"
        case .named(let slug):
            return "/search/named/\(slug)"
        case .qid(let qid):
            return "/search/qid/\(qid)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .search:
            return .post
        case .named:
            return .get
        case .qid:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .search(searchQuery, screen, page):
            return requestJSONQueryString(searchQuery, parameters: ["page": page, "screen": screen])
        default:
            return .requestPlain
        }
    }
}

extension SuggestService: TargetType {
    var path: String {
        return "/suggest"
    }
    var method: Moya.Method {
        return .post
    }
    var task: Task {
        switch self {
        case let .suggest(text, searchQuery):
            return .requestJSONEncodable(SuggestPayload(text: text, searchQuery: searchQuery))
        }
    }

    struct SuggestPayload: Codable {
        var text: String
        var searchQuery: SearchQuery
    }
}

extension SearchFilterService: TargetType {
    var path: String {
        switch self {
        case .count:
            return "/search/filter"
        case .areas:
            return "/search/filter/areas"
        case .betweenSearch:
            return "/search/filter/between/search"
        }
    }
    var method: Moya.Method {
        switch (self) {
        case .areas:
            return .get
        default:
            return .post
        }
    }
    var task: Task {
        switch self {
        case .count(let searchQuery):
            return .requestJSONEncodable(searchQuery)
        case .areas:
            return .requestPlain
        case .betweenSearch(let text):
            return .requestJSONEncodable(BetweenSearchPayload(text: text))
        }
    }

    struct BetweenSearchPayload: Codable {
        var text: String
    }
}

struct FilterResult: Codable {
    var count: Int
    var tagGraph: TagGraph
    var priceGraph: PriceGraph

    struct TagGraph: Codable {
        var tags: [Tag]

        struct Tag: Codable {
            var tagId: String
            var type: String
            var name: String
            var count: Int
        }
    }

    struct PriceGraph: Codable {
        var min: Double
        var max: Double

        var points: [Point]
        var ranges: [String: Range]

        struct Point: Codable {
            var price: Double
            var count: Int
        }

        struct Range: Codable {
            var min: Double
            var max: Double
        }
    }
}

struct SearchQuery: Codable {
    var filter: Filter
    var sort: Sort

    struct Filter: Codable {
        var price: Price?
        var hour: Hour?

        var tags = [Tag]()
        var location = Location()

        struct Price: Codable {
            var name: String?
            var min: Double
            var max: Double
        }

        struct Hour: Codable {
            var type: HourType

            var day: String
            var open: String
            var close: String

            enum HourType: String, Codable {
                case OpenNow
                case OpenDay
            }
        }

        struct Location: Codable {
            var type: LocationType = .Anywhere
            var areas = [Area]()
            var points = [Point]()

            struct Point: Codable {
                var name: String
                var latLng: String
            }

            /**
             * Follows strict API don't need defensive checks
             */
            enum LocationType: String, Codable {
                case Between
                case Where
                case Nearby
                case Anywhere
            }
        }
    }

    // See MunchCore for the available sort methods
    struct Sort: Codable, Equatable {
        var type: String?
    }
}

extension SearchQuery {
    init() {
        self.init(filter: SearchQuery.Filter(), sort: SearchQuery.Sort())

        if let tags = UserSetting.instance?.search.tags {
            if (tags.contains("halal")) {
                filter.tags.append(Tag(
                        tagId: "abb22d3d-7d23-4677-b4ef-a3e09f2f9ada",
                        name: "Halal",
                        type: .Amenities
                ))
            }

            if (tags.contains("vegetarian options")) {
                filter.tags.append(Tag(
                        tagId: "fdf77b3b-8f90-419f-b711-dd25f97046fe",
                        name: "Vegetarian Options",
                        type: .Amenities
                ))
            }
        }
    }
}

/**
 Search typed Cards
 Access json through the subscript
 */
struct SearchCard {
    private static let decoder = JSONDecoder()

    var cardId: String
    var uniqueId: String?
    var instanceId: String

    private var dictionary: [String: Any]

    /**
     * Create card locally with cardId
     */
    init(cardId: String, dictionary: [String: Any] = [:]) {
        self.cardId = cardId
        self.instanceId = String(arc4random())
        self.dictionary = dictionary
    }

    init(dictionary: [String: Any]) {
        self.dictionary = dictionary
        self.cardId = dictionary["_cardId"] as! String
        self.uniqueId = dictionary["_uniqueId"] as? String
        self.instanceId = String(arc4random())
    }

    subscript(name: String) -> Any? {
        return dictionary[name]
    }
}

// Helper Method
extension SearchCard {
    func string(name: String) -> String? {
        return self[name] as? String
    }

    func int(name: String) -> Int? {
        return self[name] as? Int
    }

    func decode<T>(name: String, _ type: T.Type) -> T? where T: Decodable {
        do {
            if let dict = self[name] {
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try SearchCard.decoder.decode(type, from: data)
            }
        } catch {
            print(error)
            Crashlytics.sharedInstance().recordError(error)
        }
        return nil
    }
}

extension SearchCard: Equatable {
    static func ==(lhs: SearchCard, rhs: SearchCard) -> Bool {
        return lhs.cardId == rhs.cardId && lhs.uniqueId == rhs.uniqueId
    }
}

//extension SearchQuery: Equatable {
//    static func ==(lhs: SearchQuery, rhs: SearchQuery) -> Bool {
//        return lhs.filter.price.name == rhs.filter.price.name &&
//                lhs.filter.price.min == rhs.filter.price.min &&
//                lhs.filter.price.max == rhs.filter.price.max &&
//
//                lhs.filter.tag.positives == rhs.filter.tag.positives &&
//
//                lhs.filter.hour.name == rhs.filter.hour.name &&
//                lhs.filter.hour.day == rhs.filter.hour.day &&
//                lhs.filter.hour.open == rhs.filter.hour.open &&
//                lhs.filter.hour.close == rhs.filter.hour.close &&
//
//                lhs.filter.area?.areaId == rhs.filter.area?.areaId &&
//
//                lhs.sort.type == rhs.sort.type
//    }
//}