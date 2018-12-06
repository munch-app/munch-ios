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
    case images(String, String?)
    case articles(String, String?)
}

extension PlaceService: TargetType {
    var path: String {
        switch self {
        case .get(let placeId): return "/places/\(placeId)"
        case .images(let placeId, _): return "/places/\(placeId)/images"
        case .articles(let placeId, _): return "/places/\(placeId)/articles"
        }
    }
    var method: Moya.Method {
        return .get
    }
    var task: Task {
        switch self {
        case .get:
            return .requestPlain
        case .articles(_, let sort):
            fallthrough
        case .images(_, let sort):
            if let sort = sort {
                return .requestParameters(parameters: ["next.sort": sort, "size": "20"], encoding: URLEncoding.default)
            }
            return .requestParameters(parameters: ["size": "20"], encoding: URLEncoding.default)
        }
    }
}

struct PlaceData: Codable {
    var place: Place
    var awards: [UserPlaceCollection.Item]
    var articles: [Article]
    var images: [PlaceImage]
}

struct Article: Codable {
    var articleId: String
    var sort: String

    var domainId: String
    var domain: Domain

    var url: String
    var title: String?
    var description: String?

    var thumbnail: Image?
    var createdMillis: Int?

    struct Domain: Codable {
        var name: String
        var url: String
    }
}

struct PlaceImage: Codable {
    var imageId: String
    var sort: String
    var sizes: [Image.Size]

    var title: String?
    var caption: String?

    var article: Article?
    var instagram: Instagram?
    var createdMillis: Int?

    struct Article: Codable {
        var articleId: String
        var url: String

        var domainId: String
        var domain: Domain

        struct Domain: Codable {
            var name: String
            var url: String
        }
    }

    struct Instagram: Codable {
        var accountId: String
        var mediaId: String

        var link: String?
        var username: String?
    }
}
