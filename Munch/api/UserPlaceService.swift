//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

enum UserSavedPlaceService {
    case list(Int?, Int)
    case put(String)
    case delete(String)
}

enum UserRecentPlaceService {
    case put(String)
}

extension UserRecentPlaceService: TargetType {
    var path: String {
        switch self {
        case .put(let placeId):
            return "/users/recent/places/\(placeId)"
        }
    }

    var method: Moya.Method {
        return .put
    }

    var task: Task {
        return .requestPlain
    }
}

extension UserSavedPlaceService: TargetType {
    // next.createdMillis
    var path: String {
        switch self {
        case .list:
            return "/users/saved/places"

        case .put(let placeId): fallthrough
        case .delete(let placeId):
            return "/users/saved/places/\(placeId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .list: return .get
        case .put: return .put
        case .delete: return .delete
        }
    }

    var task: Task {
        switch self {
        case let .list(next, size):
            if let next = next {
                return .requestParameters(parameters: ["next.createdMillis": next, "size": size], encoding: URLEncoding.default)
            }
            return .requestParameters(parameters: ["size": "20"], encoding: URLEncoding.default)

        default:
            return .requestPlain
        }
    }
}

struct UserSavedPlace: Codable {
    var userId: String
    var placeId: String
    var name: String

    var createdMillis: Int
    var place: Place?
}