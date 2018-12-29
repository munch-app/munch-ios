//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift
import RealmSwift

import Crashlytics

enum SearchService {
    case search(SearchQuery, Int)

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
        case let .search(searchQuery, page):
            return requestJSONQueryString(searchQuery, parameters: ["page": page])
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

struct FilterTag: Codable {
    var tagId: String
    var name: String
    var type: String
    var count: Int
}

struct FilterResult: Codable {
    var count: Int
    var tagGraph: TagGraph
    var priceGraph: PriceGraph?

    struct TagGraph: Codable {
        var tags: [FilterTag]
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

struct SuggestResult: Codable {
    var suggests: [String]
    var places: [Place]
    var assumptions: [AssumptionQueryResult]
}

struct AssumptionQueryResult: Codable {
    var searchQuery: SearchQuery
    var tokens: [AssumptionToken]
    var places: [Place]
    var count: Int
}

struct AssumptionToken: Codable {
    var text: String?
    var type: AssumptionType

    enum AssumptionType: String, Codable {
        case tag
        case text
        case others

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "tag": self = .tag
            case "text": self = .text
            default: self = .others
            }
        }
    }
}

struct SearchQuery: Codable {
    static let version = "2018-11-28"

    var feature: Feature
    var collection: Collection?

    var filter: Filter
    var sort: Sort

    enum Feature: String, Codable {
        case Home
        case Search
        case Location
        case Collection
        case Occasion
    }

    struct Filter: Codable {
        init() {
            UserSearchPreference.instance?.requirements.forEach { tag in
                tags.append(tag)
            }
        }

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

    struct Collection: Codable {
        var name: String?
        var collectionId: String
    }
}

extension SearchQuery {
    init(collection: SearchQuery.Collection) {
        self.init(feature: .Collection, collection: collection, filter: SearchQuery.Filter(), sort: SearchQuery.Sort())
    }

    init(feature: SearchQuery.Feature) {
        self.init(feature: feature, collection: nil, filter: SearchQuery.Filter(), sort: SearchQuery.Sort())
    }

    init() {
        self.init(feature: .Search, collection: nil, filter: SearchQuery.Filter(), sort: SearchQuery.Sort())
    }
}

extension SearchQuery {
    func isSimple() -> Bool {
        if self.sort.type != nil {
            return false
        }

        if self.filter.tags.count > 0 {
            return false
        }

        if self.filter.hour != nil {
            return false
        }

        if self.filter.price != nil {
            return false
        }


        switch self.filter.location.type {
        case .Where:
            return false

        case .Between:
            return false

        default:
            return true
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