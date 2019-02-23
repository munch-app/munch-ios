//
// Created by Fuxing Loh on 2019-01-24.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import os.log

import Foundation
import FirebaseAnalytics
import FBSDKCoreKit

class MunchAnalytic {
    static func clearUserData() {
        os_log("MunchAnalytic clearUserData")
        guard Env.isProduction else {
            return
        }

        Analytics.setUserID(nil)
        FBSDKAppEvents.clearUserID()
        FBSDKAppEvents.clearUserData()
    }

    static func setUserId(userId: String) {
        os_log("MunchAnalytic setUserId: %@", type: .info, userId)
        guard Env.isProduction else {
            return
        }

        Analytics.setUserID(userId)
        FBSDKAppEvents.setUserID(userId)
    }

    // Only tracked in Firebase
    static func setScreen(_ name: String) {
        os_log("MunchAnalytic setScreen: %@", type: .info, name)
        guard Env.isProduction else {
            return
        }

        Analytics.setScreenName(name, screenClass: nil)
        FBSDKAppEvents.logEvent("setScreen", parameters: [
        "name": name as NSObject
        ])
    }

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        let p = "\(parameters?.count ?? 0)"
        os_log("MunchAnalytic logEvent: %@, p: %@", type: .info, name, p)
        guard Env.isProduction else {
            return
        }

        Analytics.logEvent(name, parameters: parameters)

        if let parameters = parameters {
            FBSDKAppEvents.logEvent(name, parameters: parameters)
        } else {
            FBSDKAppEvents.logEvent(name)
        }
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

        if case .Search = searchQuery.feature {
            if case .Between = searchQuery.filter.location.type {
                MunchAnalytic.logEvent("search_query_eat_between", parameters: [
                    "count": searchQuery.filter.location.points.count as NSObject
                ])
            }
        }
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