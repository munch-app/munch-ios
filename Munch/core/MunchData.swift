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

        struct Article: Codable {
            var profile: Int
            var single: Int
            var list: Int
            var total: Int
        }

        struct Instagram: Codable {
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

    class Formatter {
        private let inFormatter = DateFormatter()
        private let outFormatter = DateFormatter()
        private let dayFormatter = DateFormatter()

        public enum Open {
            case open
            case opening
            case closed
            case closing
            case none
        }

        init() {
            inFormatter.locale = Locale(identifier: "en_US_POSIX")
            inFormatter.dateFormat = "HH:mm"

            outFormatter.locale = Locale(identifier: "en_US_POSIX")
            outFormatter.dateFormat = "h:mma"
            outFormatter.amSymbol = "am"
            outFormatter.pmSymbol = "pm"

            dayFormatter.locale = Locale(identifier: "en_US_POSIX")
            dayFormatter.dateFormat = "EEE"
        }

        private static let instance = Formatter()

        class func parse(open: String, close: String) -> String {
            return "\(parse(time: open)) - \(parse(time: close))"
        }

        class func parse(time: String) -> String {
            // 24:00 problem
            if (time == "24:00" || time == "23:59") {
                return "Midnight"
            }
            let date = instance.inFormatter.date(from: time)
            return instance.outFormatter.string(from: date!)
        }

        class func timeNow() -> String {
            return instance.inFormatter.string(from: Date())
        }

        class func dayNow() -> String {
            return instance.dayFormatter.string(from: Date())
        }

        class func day(addingDay day: Int = 0) -> String {
            let dateTmr = Calendar.current.date(byAdding: .day, value: day, to: Date())
            return instance.dayFormatter.string(from: dateTmr!)
        }

        class func timeAs(int time: String?) -> Int? {
            if let time = time {
                let split = time.split(separator: ":")
                if let hour = split.get(0), let min = split.get(1) {
                    if let h = Int(hour), let m = Int(min) {
                        return h * 60 + m
                    }
                }
            }
            return nil
        }

        class func isBetween(hour: Hour, date: Date, opening: Int = 0, closing: Int = 0) -> Bool {
            let now = timeAs(int: instance.inFormatter.string(from: date))!
            let open = timeAs(int: hour.open)
            let close = timeAs(int: hour.close)

            if let open = open, let close = close {
                if (close < open) {
                    return open - opening <= now && now + closing <= 2400
                }
                return open - opening <= now && now + closing <= close
            }
            return false
        }

        class func isOpen(hours: [Hour], opening: Int = 30) -> Open {
            if (hours.isEmpty) {
                return Open.none
            }

            let date = Date()
            let currentDay = day().lowercased()
            let currentHours = hours.filter({ $0.day.rawValue == currentDay })

            for hour in currentHours {
                if (isBetween(hour: hour, date: date)) {
                    if (!isBetween(hour: hour, date: date, closing: 30)) {
                        return Open.closing
                    }
                    return Open.open
                } else if isBetween(hour: hour, date: date, opening: 30) {
                    return Open.opening
                }
            }

            return Open.closed
        }
    }
}

protocol ElasticObject: Codable {
//    var dataType: String { get }
//    var createdMillis: Int { get }
//    var updatedMillis: Int { get }
}