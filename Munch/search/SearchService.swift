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
    case search(SearchQuery, String, Int)

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
        case .named:
            return .get
        case .qid:
            return .get
        case .search:
            return .post
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
            var min: Double?
            var max: Double?
        }

        struct Hour: Codable {
            var type: HourType?

            var day: String?
            var open: String?
            var close: String?

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