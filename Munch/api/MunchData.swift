//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

struct Place: ElasticObject, Codable {
    var placeId: String
    var status: Status

    var name: String
    var tags: [Tag]

    var phone: String?
    var website: String?
    var description: String?

    var menu: Menu?
    var price: Price?

    var location: Location

    var hours: [Hour]
    var images: [Image]
    var areas: [Area]

    var createdMillis: Int?

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

            var name: String {
                switch self {
                case .open: return "Open"
                case .closed: return "Perm Closed"
                case .renovation: return "On Renovation"
                case .moved: return "Perm Moved"
                case .other: return ""
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
}

struct Area: ElasticObject, Codable {
    var areaId: String

    var type: AreaType
    var name: String

    var website: String?
    var description: String?

    var images: [Image]?
    var hour: [Hour]?
    var counts: Counts?

    var location: Location

    enum AreaType: String, Codable {
        case City
        case Superset
        case Region
        case Cluster
        case Generated
        case Other

        /// Defensive Decoding
        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "City": self = .City
            case "Superset": self = .Superset
            case "Region": self = .Region
            case "Cluster": self = .Cluster
            case "Generated": self = .Generated
            default: self = .Other
            }
        }
    }

    struct Counts: Codable {
        var total: Int?
    }
}

extension Area {
    public static var anywhere: Area {
        let points = ["1.26675774823,103.603134155", "1.32442122318,103.617553711", "1.38963424766,103.653259277", "1.41434608581,103.666305542", "1.42944763543,103.671798706", "1.43905766081,103.682785034", "1.44386265833,103.695831299", "1.45896401284,103.720550537", "1.45827758983,103.737716675", "1.44935407163,103.754196167", "1.45004049736,103.760375977", "1.47887018872,103.803634644", "1.4754381021,103.826980591", "1.45827758983,103.86680603", "1.43219336108,103.892211914", "1.4287612035,103.897018433", "1.42670190649,103.915557861", "1.43219336108,103.934783936", "1.42189687297,103.960189819", "1.42464260763,103.985595703", "1.42121043879,104.000701904", "1.43974408965,104.02130127", "1.44592193988,104.043960571", "1.42464260763,104.087219238", "1.39718511473,104.094772339", "1.35737118164,104.081039429", "1.29009788407,104.127044678", "1.277741368,104.127044678", "1.25371463932,103.982162476", "1.17545464492,103.812561035", "1.13014521522,103.736343384", "1.19055762617,103.653945923", "1.1960495989,103.565368652", "1.26675774823,103.603134155"]
        let location = Location(address: nil, street: nil, unitNumber: nil, neighbourhood: nil,
                city: "Singapore", country: "SGP", postcode: nil, latLng: "1.290270, 103.851959",
                polygon: Location.Polygon(points: points), landmarks: nil)

        return Area(
                areaId: "30918bf3-eeaf-43f3-b27c-afc3128acd16",
                type: .City,
                name: "Singapore",
                website: nil,
                description: nil,
                images: nil,
                hour: nil,
                counts: nil,
                location: location)
    }
}

struct Landmark: ElasticObject, Codable {
    var landmarkId: String

    var type: LandmarkType
    var name: String
    var location: Location

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

    var landmarks: [Landmark]?

    struct Polygon: Codable {
        var points: [String]?
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

    enum IsOpen {
        case open
        case opening
        case closed
        case closing
        case none
    }
}

extension Hour {
    public static let machineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    public static let humanFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }()

    var timeRange: String {
        return "\(Hour.parse(time: open)) - \(Hour.parse(time: close))"
    }

    static func timeAs(int time: String?) -> Int? {
        if let time = time {
            let split = time.split(separator: ":")
            if let hour = split.get(0), let min = split.get(1) {
                if let h = Int(hour), let m = Int(min) {
                    return (h * 60) + m
                }
            }
        }
        return nil
    }

    func isBetween(date: Date, opening: Int = 0, closing: Int = 0) -> Bool {
        let now = Hour.timeAs(int: Hour.machineFormatter.string(from: date))!

        if let open = Hour.timeAs(int: self.open), let close = Hour.timeAs(int: self.close) {
            if (close < open) {
                return open - opening <= now && now + closing <= 2400
            }
            return open - opening <= now && now + closing <= close
        }
        return false
    }

    private static func parse(time: String) -> String {
        // 24:00 problem
        if (time == "24:00" || time == "23:59") {
            return "Midnight"
        }
        let date = machineFormatter.date(from: time)
        return humanFormatter.string(from: date!)
    }
}

extension Hour.Day {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    var text: String {
        switch self {
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        case .sun: return "Sun"
        case .other: return "Day"
        }
    }

    static var today: Hour.Day {
        return self.add(days: 0)
    }

    static func add(days: Int = 0) -> Hour.Day {
        if let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
            switch dayFormatter.string(from: date).lowercased() {
            case "mon": return .mon
            case "tue": return .tue
            case "wed": return .wed
            case "thu": return .thu
            case "fri": return .fri
            case "sat": return .sat
            case "sun": return .sun
            default: return .other
            }
        }
        return .other
    }

    var isToday: Bool {
        return Hour.Day.isToday(day: self)
    }

    static func isToday(day: Hour.Day) -> Bool {
        return day == Hour.Day.today
    }
}

extension Hour {
    class Grouped {
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "en_US_POSIX")

            return formatter
        }()

        let hours: [Hour]
        let dayHours: [Hour.Day: String]

        init(hours: [Hour]) {
            self.hours = hours

            var dayHours = [Hour.Day: String]()
            for hour in hours.sorted(by: { $0.open < $1.open }) {
                if let timeRange = dayHours[hour.day] {
                    dayHours[hour.day] = timeRange + ", " + hour.timeRange
                } else {
                    dayHours[hour.day] = hour.timeRange
                }
            }
            self.dayHours = dayHours
        }

        subscript(day: Hour.Day) -> String {
            get {
                return dayHours[day] ?? "Closed"
            }
        }

        func isOpen(opening: Int = 30) -> Hour.IsOpen {
            return hours.isOpen(opening: opening)
        }

        var todayDayTimeRange: String {
            let dayInWeek = Grouped.dateFormatter.string(from: Date())
            return dayInWeek.capitalized + ": " + self[Hour.Day.today]
        }
    }
}

extension Array where Element == Hour {
    func isOpen(opening: Int = 30) -> Hour.IsOpen {
        if (self.isEmpty) {
            return .none
        }

        let date = Date()
        let currentDay = Hour.Day.today
        let currentHours = self.filter({ $0.day == currentDay })

        for hour in currentHours {
            if hour.isBetween(date: date) {
                if !hour.isBetween(date: date, closing: 30) {
                    return .closing
                }
                return .open
            } else if hour.isBetween(date: date, opening: 30) {
                return .opening
            }
        }

        return .closed
    }

    var grouped: Hour.Grouped {
        return Hour.Grouped(hours: self)
    }
}

protocol ElasticObject: Codable {
}