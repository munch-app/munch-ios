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

enum UserRatedPlaceService {
    case put(String, UserRatedPlace)
}

extension UserRatedPlaceService: TargetType {
    var path: String {
        switch self {
        case let .put(placeId, _):
            return "/users/rated/places/\(placeId)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .put:
            return .put
        }
    }
    var task: Task {
        switch self {
        case let .put(_ ,place):
            return .requestJSONEncodable(place)
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

struct UserRatedPlace: Codable {
    var userId: String?
    var placeId: String?

    var rating: Rating
    var status: Status

    var updatedMillis: Int?
    var createdMillis: Int?

    enum Status: String, Codable {
        case draft
        case published
        case deleted
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "draft": self = .draft
            case "published": self = .published
            case "deleted": self = .deleted
            default: self = .other
            }
        }
    }

    enum Rating: String, Codable {
        case star1
        case star2
        case star3
        case star4
        case star5
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "star1": self = .star1
            case "star2": self = .star2
            case "star3": self = .star3
            case "star4": self = .star4
            case "star5": self = .star5
            default: self = .other
            }
        }

        var count: Int {
            switch self {
            case .star1:
                return 1
            case .star2:
                return 2
            case .star3:
                return 3
            case .star4:
                return 4
            case .star5:
                return 5
            default:
                return 0
            }
        }
    }
}