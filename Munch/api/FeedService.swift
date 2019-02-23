//
// Created by Fuxing Loh on 2018-11-29.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

enum FeedQueryService {
    // FeedQuery, next.from, size
    case query(FeedQuery, Int?, Int)
}

extension FeedQueryService: TargetType {
    var path: String {
        switch self {
        case .query: return "/feed/query"
        }
    }

    var method: Moya.Method {
        switch self {
        case .query: return .post
        }
    }

    var task: Task {
        switch self {
        case let .query(query, nextFrom, size):
            var param = ["size": size]
            if let from = nextFrom {
                param["next.from"] = from
            }
            return requestJSONQueryString(query, parameters: param)
        }

    }
}

struct FeedQuery: Codable {
    var location: Location

    struct Location: Codable {
        var latLng: String?
    }
}

struct FeedItem: Codable {
    var itemId: String
    var type: ItemType
    var sort: String

    var country: String
    var latLng: String

    var author: String?
    var title: String?

    var places: [Place]
    var createdMillis: Int

    var image: Image?
    var instagram: Instagram?

    enum ItemType: String, Codable {
        case Article
        case InstagramMedia
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "Article": self = .Article
            case "InstagramMedia": self = .InstagramMedia
            default: self = .Other
            }
        }
    }

    struct Place: Codable {
        var placeId: String
    }

    struct Instagram: Codable {
        var accountId: String
        var mediaId: String
        var link: String?

        var type: String?
        var caption: String?

        var userId: String?
        var username: String?
    }
}