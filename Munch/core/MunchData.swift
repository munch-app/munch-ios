//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

struct Place: ElasticObject, Codable {
    var placeId: String
    var status: Status

    var name: String
    var names: [String]
    var tags: [Tag]

    var phone: String?
    var website: String?
    var description: String?

    var menu: Menu?
    var price: Price?
    var counts: Counts?

    var location: Location

    var hours: [Hour]
    var images: [Image]
    var areas: [Area]

    var createdMillis: Int?
    var updatedMillis: Int?

    var ranking: Double?

    struct Status: Codable {
        var type: StatusType
        var moved: Moved?
        var updatedMillis: Int?

        enum StatusType: String, Codable {
            case open
            case renovation
            case closed
            case moved
            case other

            /// Defensive Decoding
            init(from decoder: Decoder) throws {
                switch try decoder.singleValueContainer().decode(String.self) {
                case "open": self = .open
                case "renovation": self = .renovation
                case "closed": self = .closed
                case "moved": self = .moved
                default: self = .other
                }
            }
        }

        struct Moved: Codable {
            var placeId: String
        }
    }

    struct Menu: Codable {
        var url: String?
    }

    struct Price: Codable {
        var perPax: Double?
    }

    struct Counts: Codable {
        var article: Article?
        var instagram: Instagram?

        struct Article {
            var profile: Int
            var single: Int
            var list: Int
            var total: Int
        }

        struct Instagram {
            var profile: Int
            var total: Int
        }
    }
}

struct Area: ElasticObject, Codable {
    var areaId: String

    var type: AreaType
    var name: String
    var names: [String]?

    var website: String?
    var description: String?

    var images: [Image]?
    var hour: [Hour]?

    var location: Location

    var updatedMillis: Int?
    var createdMillis: Int?

    enum AreaType: String, Codable {
        case City
        case Region
        case Cluster
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "City": self = .City
            case "Region": self = .Region
            case "Cluster": self = .Cluster
            default: self = .Other
            }
        }
    }
}

struct Landmark: ElasticObject, Codable {
    var landmarkId: String

    var type: LandmarkType
    var name: String
    var location: Location

    var updatedMillis: Int?
    var createdMillis: Int?

    enum LandmarkType: String, Codable {
        case train
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "train": self = .train
            default: self = .other
            }
        }
    }
}

struct Tag: ElasticObject, Codable {
    var tagId: String
    var name: String
    var type: TagType

    var names: [String]?
    var createdMillis: Int?
    var updatedMillis: Int?

    enum TagType: String, Codable {
        case Food
        case Cuisine
        case Establishment
        case Amenities
        case Timing
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "Food": self = .Food
            case "Cuisine": self = .Cuisine
            case "Establishment": self = .Establishment
            case "Amenities": self = .Amenities
            case "Timing": self = .Timing
            default: self = .Other
            }
        }
    }
}

struct Location: Codable {
    var address: String?
    var street: String?
    var unitNumber: String?
    var neighbourhood: String?

    var city: String?
    var country: String?
    var postcode: String?

    var latLng: String?
    var polygon: Polygon?

    var landmarks: [Landmark]

    struct Polygon: Codable {
        var points: [String]
    }
}

struct Hour: Codable {
    var day: Day
    var open: String
    var close: String

    enum Day: String, Codable {
        case mon
        case tue
        case wed
        case thu
        case fri
        case sat
        case sun
        case other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "mon": self = .mon
            case "tue": self = .tue
            case "wed": self = .wed
            case "thu": self = .thu
            case "fri": self = .fri
            case "sat": self = .sat
            case "sun": self = .sun
            default: self = .other
            }
        }
    }
}

protocol ElasticObject: Codable {
//    var dataType: String { get }
//    var createdMillis: Int { get }
//    var updatedMillis: Int { get }
}