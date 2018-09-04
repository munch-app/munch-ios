//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum SearchSuggestType {
    case empty
    case loading
    case headerRestaurant
    case place(Place)

    case rowRecent
    case rowAssumption(AssumptionQueryResult)
    case rowSuggest([String])
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

struct SuggestData: Codable {
    var places: [Place]
    var assumptions: [AssumptionQueryResult]
    var suggests: [String]
}

extension SuggestData {
    var items: [SearchSuggestType] {
        var list = [SearchSuggestType]()
        if !suggests.isEmpty {
            list.append(.rowSuggest(suggests))
        }

        for assumption in assumptions {
            list.append(.rowAssumption(assumption))
        }

        if !places.isEmpty {
            list.append(.headerRestaurant)
            for place in places {
                list.append(.place(place))
            }
        }

        if list.isEmpty {
            list.append(.empty)
        }

        return list
    }
}