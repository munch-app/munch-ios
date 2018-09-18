//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift

import Crashlytics

enum PlaceService {
    case get(String)
    case cards(String)
}

enum PlacePartnerService {
    case articles(String, String?, Int)
    case medias(String, String?, Int)
}

extension PlaceService: TargetType {
    var path: String {
        switch self {
        case .get(let placeId): return "/places/\(placeId)"
        case .cards(let placeId): return "/places/\(placeId)/cards"
        }
    }
    var method: Moya.Method {
        return .get
    }
    var task: Task {
        return .requestPlain
    }
}

extension PlacePartnerService: TargetType {
    var path: String {
        switch self {
        case .articles(let placeId, _, _): return "/places/\(placeId)/partners/articles"
        case .medias(let placeId, _, _): return "/places/\(placeId)/partners/instagram/medias"
        }
    }
    var method: Moya.Method {
        return .get
    }
    var task: Task {
        switch self {
        case .articles(_, let next, let size):
            return .requestParameters(parameters: ["size": size, "next.placeSort": next as Any], encoding: URLEncoding.default)

        case .medias(_, let sort, let size):
            var parameters: [String: Any] = ["size": size]
            if sort != nil {
                parameters["next.sort"] = sort
            }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
    }
}

struct Article: Codable {
    var articleId: String?
    var articleListNo: String?

    var placeId: String?
    var placeSort: String?
    var placeName: String?

    var url: String?
    var brand: String?
    var title: String?
    var description: String?

    var thumbnail: [String: String]?
}

struct InstagramMedia: Codable {
    var accountId: String?
    var mediaId: String?
    var link: String?

    var image: Image?

    var user: User?
    var type: String?
    var caption: String?

    var createdMillis: Int?

    struct User: Codable {
        var userId: String?
        var username: String?
        var fullName: String?
        var profileImage: Image?
    }
}