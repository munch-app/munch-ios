//
// Created by Fuxing Loh on 2019-01-24.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import os.log

import Foundation
import FirebaseAnalytics

class MunchAnalytic {
    static func setUserId(userId: String?) {
        Analytics.setUserID(userId)
        os_log("MunchAnalytic setUserId: %@", type: .info, userId ?? "")
    }

    // Place it at view did appear
    static func setScreen(_ name: String) {
        Analytics.setScreenName(name, screenClass: nil)
        os_log("MunchAnalytic setScreen: %@", type: .info, name)
    }

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        let p = "\(parameters?.count ?? 0)"
        os_log("MunchAnalytic logEvent: %@, p: %@", type: .info, name, p)
    }

    private static func searchQueryParameters(searchQuery: SearchQuery) -> [String: Any] {
        var parameters: [String: Any] = [
            "feature": searchQuery.feature.rawValue as NSObject
        ]

        if case .Search = searchQuery.feature {
            parameters["tag_count"] = searchQuery.filter.tags.count as NSObject
            parameters["price_selected"] = (searchQuery.filter.price != nil) as NSObject

            if let type = searchQuery.filter.hour?.type {
                parameters["hour_type"] = type.rawValue
            }

            parameters["location_type"] = searchQuery.filter.location.type.rawValue as NSObject
            if case .Between = searchQuery.filter.location.type {
                parameters["location_count"] = searchQuery.filter.location.points.count as NSObject
            } else {
                parameters["location_count"] = searchQuery.filter.location.areas.count as NSObject
            }
        }

        return parameters
    }

    static func logSearchQuery(searchQuery: SearchQuery) {
        let parameters = searchQueryParameters(searchQuery: searchQuery)
        MunchAnalytic.logEvent("search_query", parameters: parameters)
    }

    static func logSearchQueryAppend(searchQuery: SearchQuery, cards: [SearchCard], page: Int) {
        if cards.isEmpty {
            return
        }

        MunchAnalytic.logEvent("search_query_append", parameters: [
            "feature": searchQuery.feature.rawValue as NSObject,
            "count": cards.count as NSObject,
            "page": page as NSObject
        ])
    }

    static func logSearchQueryShare(searchQuery: SearchQuery, trigger: String) {
        var parameters = searchQueryParameters(searchQuery: searchQuery)
        parameters["trigger"] = trigger as NSObject
        MunchAnalytic.logEvent("search_query_share", parameters: parameters)
    }
}