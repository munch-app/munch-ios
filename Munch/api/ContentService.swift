//
// Created by Fuxing Loh on 2019-02-27.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

enum CreatorContentService {
    case get(String)
}

extension CreatorContentService: TargetType {
    var path: String {
        switch self {
        case let .get(contentId):
            return "/contents/\(contentId)"
        }
    }
    var method: Moya.Method {
        return .get

    }
    var task: Task {
        return .requestPlain
    }
}

enum CreatorContentItemService {
    case list(String, String?)
}

extension CreatorContentItemService: TargetType {
    var path: String {
        switch self {
        case let .list(contentId, _):
            return "/contents/\(contentId)"
        }
    }
    var method: Moya.Method {
        return .get
    }
    var task: Task {
        switch self {
        case let .list(_, nextItemId):
            if let nextItemId = nextItemId {
                return .requestParameters(parameters: ["next.itemId": nextItemId, "size": "30"], encoding: URLEncoding.default)
            }
            return .requestParameters(parameters: ["size": "30"], encoding: URLEncoding.default)
        }
    }
}

struct CreatorSeries: Codable {
    var creatorId: String
    var seriesId: String
    var sortId: String
    var status: Status

    var title: String?
    var subtitle: String?
    var body: String?

    var image: Image?
    var tags: [String]

    var createdMillis: Int
    var updatedMillis: Int

    enum Status: String, Codable {
        case draft
        case published
        case archived
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "draft": self = .draft
            case "published": self = .published
            case "archived": self = .archived
            default: self = .other
            }
        }
    }
}

struct CreatorContent: Codable {
    var creatorId: String
    var contentId: String
    var sortId: String
    var status: Status

    var title: String?
    var subtitle: String?
    var body: String?

    var image: Image?
    var tags: [String]
    var platform: String

    var createdMillis: Int
    var updatedMillis: Int

    enum Status: String, Codable {
        case draft
        case published
        case archived
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "draft": self = .draft
            case "published": self = .published
            case "archived": self = .archived
            default: self = .other
            }
        }
    }
}

enum CreatorContentItemType: String, Codable {
    case place = "place"
    case line = "line"
    case image = "image"

    case title = "title"
    case h1 = "h1"
    case h2 = "h2"
    case text = "text"

    case quote = "quote"
    case html = "html"
}

struct CreatorContentItem: Codable {
    var contentId: String
    var itemId: String
    var type: String

    var linkedId: String?
    var linkedSort: String?
}