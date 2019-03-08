//
// Created by Fuxing Loh on 2019-02-27.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import Moya

private let b2d: [String: String] = [
    "A": ".", "B": "0", "C": "1", "D": "2", "E": "3", "F": "4", "G": "5", "H": "6", "I": "7", "J": "8", "K": "9", "L": "A", "M": "B", "N": "C", "O": "D", "P": "E", "Q": "F", "R": "G", "S": "H", "T": "I", "U": "J", "V": "K", "W": "L", "X": "M", "Y": "N", "Z": "O", "a": "P", "b": "Q", "c": "R", "d": "S", "e": "T", "f": "U", "g": "V", "h": "W", "i": "X", "j": "Y", "k": "Z", "l": "_", "m": "a", "n": "b", "o": "c", "p": "d", "q": "e", "r": "f", "s": "g", "t": "h", "u": "i", "v": "j", "w": "k", "x": "l", "y": "m", "z": "n", "0": "o", "1": "p", "2": "q", "3": "r", "4": "s", "5": "t", "6": "u", "7": "v", "8": "w", "9": "x", "+": "y", "/": "z",
]

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
            return "/contents/\(contentId)/items"
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

    var slug: String {
        var slug = self.title?.lowercased() ?? ""
        slug = slug.replacingOccurrences(of: " ", with: "-")
        if let regex = try? NSRegularExpression(pattern: "[^0-9a-z-]", options: .caseInsensitive) {
            return regex.stringByReplacingMatches(in: slug, options: [], range: NSRange(location: 0, length: slug.count), withTemplate: "")
        }
        return slug
    }

    var cid: String {
        let uuid = NSUUID(uuidString: self.contentId)!
        let result = uuid.data.base64EncodedString().replacingOccurrences(of: "=", with: "")
        return Array(result).map { substring -> String in
            return b2d[String(substring)]!
        }.joined()
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