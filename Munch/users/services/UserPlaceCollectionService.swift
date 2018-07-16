//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

import Crashlytics

enum UserPlaceCollectionService {
    case list(Int, String?) // size, next.sort
    case get(String)

    case post(UserPlaceCollection)
    case patch(String, UserPlaceCollection) // collectionId
    case delete(String) // collectionId

    // ITEMS
    case itemsList(String, Int, String?) // collectionId, size, next.sort
    case itemsPut(String, String) // collectionId, placeId
    case itemsDelete(String, String) // collectionId, placeId
}

extension UserPlaceCollectionService: TargetType {
    var path: String {
        switch self {
        case .list, .post:
            return "/users/places/collections"
        case let .get(collectionId), let .delete(collectionId), let .patch(collectionId, _), let .itemsList(collectionId, _, _):
            return "/users/places/collections/\(collectionId)"
        case let .itemsPut(collectionId, placeId), let .itemsDelete(collectionId, placeId):
            return "/users/places/collections/\(collectionId)/\(placeId)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .list, .get, .itemsList:
            return .get
        case .post:
            return .post
        case .patch:
            return .patch
        case .itemsPut:
            return .put
        case .itemsDelete, .delete:
            return .delete
        }
    }
    var task: Task {
        switch self {
        case let .list(size, next), let .itemsList(_, size, next):
            return .requestParameters(parameters: ["size": size, "next.sort": next as Any], encoding: URLEncoding.default)
        case let .patch(_, collection), let .post(collection):
            return .requestJSONEncodable(collection)
        case .get, .delete, .itemsDelete, .itemsPut:
            return .requestPlain
        }
    }
}

struct UserPlaceCollection: Codable {
    var collectionId: String?
    var userId: String?
    var sort: Int?

    var name: String
    var description: String?

    var access: Access
    var createdBy: CreatedBy

    var createdMillis: Int?
    var updatedMillis: Int?

    var count: Int?

    enum Access: String, Codable {
        case Public
        case Private
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "Public": self = .Public
            case "Private": self = .Private
            default: self = .Other
            }
        }
    }

    enum CreatedBy: String, Codable {
        case User
        case Award
        case ForYou
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "User": self = .User
            case "Award": self = .Award
            case "ForYou": self = .ForYou
            default: self = .Other
            }
        }
    }

    struct Item: Codable {
        var collectionId: String
        var placeId: String

        var sort: Int
        var createdMillis: Int
    }
}