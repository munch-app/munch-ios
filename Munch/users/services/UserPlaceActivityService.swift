//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift

import Crashlytics

enum UserPlaceActivityService {
    case put(UserPlaceActivity)
}

extension UserPlaceActivityService: TargetType {
    var path: String {
        switch self {
        case .put(let activity): return "/users/places/activities/\(activity.placeId)/\(activity.startedMillis)"
        }
    }
    var method: Moya.Method {
        return .put
    }
    var task: Task {
        switch self {
        case .put(let activity):
            return .requestJSONEncodable(activity)
        }
    }
}

struct UserPlaceActivity: Codable {
    var placeId: String

    var startedMillis: Int
    var endedMillis: Int?

    var actions: [Action]

    struct Action: Codable {
        var name: String
        var millis: Int
    }
}