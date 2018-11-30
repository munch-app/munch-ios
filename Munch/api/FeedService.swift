//
// Created by Fuxing Loh on 2018-11-29.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

enum FeedImageService {
    case query(String, String, Int)
    case get(String)
}

extension FeedImageService: TargetType {
    var path: String {
        switch self {
        case let .query(country, latLng, from): return "/feed/images"
        case let .get(itemId): return "/feed/images/\(itemId)"
        }
    }
    var method: Moya.Method {
        return .get
    }
    var task: Task {
        return .requestPlain
    }
}

struct ImageFeedItem: Codable {
    var itemId: String
    var sort: String

    var country: String
    var latLat: String

    var image: Image
    var createdMillis: Int

    var instagram: Instagram?
    var places: [Place]

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