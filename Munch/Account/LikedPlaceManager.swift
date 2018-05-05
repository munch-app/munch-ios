//
// Created by Fuxing Loh on 4/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import RealmSwift
import SwiftyJSON

fileprivate struct LikedPlaceState {
    var placeId: String
    var liked: Bool
}

class LikedPlaceManager {
    static let instance = LikedPlaceManager()
    private var stateHistory = [LikedPlaceState]()

    public func push(placeId: String, liked: Bool) -> Bool {
        stateHistory.append(.init(placeId: placeId, liked: liked))

        if stateHistory.count > 10 {
            stateHistory.remove(at: 0)
        }

        return liked
    }

    public func isLiked(placeId: String, defaultLike: Bool) -> Bool {
        for history in stateHistory {
            if history.placeId == placeId {
                return history.liked
            }
        }

        return defaultLike
    }
}