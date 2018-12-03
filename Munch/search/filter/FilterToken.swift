//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

// MARK: Filter View
enum FilterToken {
    case tag(Tag)
    case hour(SearchQuery.Filter.Hour)
    case price(SearchQuery.Filter.Price)
    case location(SearchQuery.Filter.Location)
}

extension FilterToken {
    var text: String {
        switch self {
        case .tag(let tag):
            return tag.name

        case .price(let price):
            let min = String(format: "%.0f", price.min)
            let max = String(format: "%.0f", price.max)
            return "$\(min) - $\(max)"

        case .location(let location):
            switch location.type {
            case .Anywhere:
                return "Anywhere"
            case .Nearby:
                return "Nearby"
            case .Between:
                return "EatBetween"
            case .Where:
                return location.areas.get(0)?.name ?? "Where"
            }

        case .hour(let hour):
            switch hour.type {
            case .OpenDay:
                let day = hour.day
                let open = hour.open
                let close = hour.close
                return "\(day): \(open)-\(close)"

            case .OpenNow:
                return "Open Now"
            }
        }
    }
}

extension FilterToken {
    static func getTokens(query: SearchQuery) -> [FilterToken] {
        var tags = [FilterToken]()
        tags.append(.location(query.filter.location))

        if let price = query.filter.price {
            tags.append(.price(price))
        }

        if let hour = query.filter.hour {
            tags.append(.hour(hour))
        }

        query.filter.tags.forEach { tag in
            tags.append(.tag(tag))
        }
        return tags
    }
}