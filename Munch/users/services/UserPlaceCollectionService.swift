//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

import Crashlytics

enum UserPlaceCollectionService {
    case list(Int, Int?) // size, next.sort
    case get(String)

    case post(UserPlaceCollection)
    case patch(String, UserPlaceCollection) // collectionId
    case delete(String) // collectionId

    // ITEMS
    case itemsList(String, Int, Int?) // collectionId, size, next.sort
    case itemsGet(String, String) // collectionId, placeId
    case itemsPut(String, String) // collectionId, placeId
    case itemsDelete(String, String) // collectionId, placeId
}

extension UserPlaceCollectionService: TargetType {
    var path: String {
        switch self {
        case .list, .post:
            return "/users/places/collections"
        case let .get(collectionId), let .delete(collectionId), let .patch(collectionId, _):
            return "/users/places/collections/\(collectionId)"
        case let .itemsList(collectionId, _, _):
            return "/users/places/collections/\(collectionId)/items"
        case let .itemsPut(collectionId, placeId), let .itemsDelete(collectionId, placeId), let .itemsGet(collectionId, placeId):
            return "/users/places/collections/\(collectionId)/items/\(placeId)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .list, .get, .itemsList, .itemsGet:
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
            var parameters: [String: Any] = ["size": size]
            if let next = next {
                parameters["next.sort"] = next
            }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case let .patch(_, collection), let .post(collection):
            return .requestJSONEncodable(collection)
        case .get, .delete, .itemsDelete, .itemsPut, .itemsGet:
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
    var image: Image?

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
        case Default
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "User": self = .User
            case "Award": self = .Award
            case "ForYou": self = .ForYou
            case "Default": self = .Default
            default: self = .Other
            }
        }
    }

    struct Item: Codable {
        var collectionId: String
        var placeId: String

        var sort: Int
        var createdMillis: Int

        var place: Place?
    }
}