//
// Created by Fuxing Loh on 2019-02-16.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

enum LocationSearchService {
    case search(String)
    case current(String)
}

fileprivate struct LocationSearchPayload: Codable {
    var text: String
}

fileprivate struct LocationCurrentPayload: Codable {
    var latLng: String
}

extension LocationSearchService: TargetType {
    var path: String {
        switch self {
        case .search:
            return "/locations/search"
        case .current:
            return "/locations/current"
        }
    }

    var method: Moya.Method {
        switch self {
        case .search:
            return .post
        case .current:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .search(text):
            return .requestJSONEncodable(LocationSearchPayload(text: text))

        case let .current(latLng):
            return .requestJSONEncodable(LocationCurrentPayload(latLng: latLng))
        }
    }
}

struct NamedLocation: Codable {
    var name: String
    var latLng: String
}