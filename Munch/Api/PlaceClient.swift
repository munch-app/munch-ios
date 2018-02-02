//
//  PlaceClient.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/**
 PlaceClient from PlaceService in munch-core/munch-api
 */
class PlaceClient {
    func get(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place?) -> Void) {
        MunchApi.restful.get("/places/\(id)") { meta, json in
            callback(meta, Place(json: json["data"]))
        }
    }

    func cards(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place?, _ cards: [PlaceCard], _ liked: Bool?) -> Void) {
        MunchApi.restful.get("/places/\(id)/cards") { meta, json in
            callback(meta,
                    Place(json: json["data"]["place"]),
                    json["data"]["cards"].map({ PlaceCard(json: $0.1) }),
                    json["data"]["user"]["liked"].bool
            )
        }
    }

    func getArticle(id: String, maxSort: String? = nil, size: Int, callback: @escaping (_ meta: MetaJSON, _ articles: [Article]) -> Void) {
        var params = Parameters()
        params["maxSort"] = maxSort
        params["size"] = size

        MunchApi.restful.get("/places/\(id)/data/article", parameters: params) { meta, json in
            callback(meta, json["data"].map({ Article(json: $0.1) }))
        }
    }

    func getInstagram(id: String, maxSort: String? = nil, size: Int, callback: @escaping (_ meta: MetaJSON, _ medias: [InstagramMedia]) -> Void) {
        var params = Parameters()
        params["maxSort"] = maxSort
        params["size"] = size

        MunchApi.restful.get("/places/\(id)/data/instagram", parameters: params) { meta, json in
            callback(meta, json["data"].map({ InstagramMedia(json: $0.1) }))
        }
    }
}

/**
 Basic and Vendor typed Cards
 Access json through the subscript
 */
struct PlaceCard {
    var cardId: String
    private(set) var data: JSON

    init(cardId: String) {
        self.cardId = cardId
        self.data = JSON(parseJSON: "{}")
    }

    init(json: JSON) {
        self.cardId = json["_cardId"].stringValue
        self.data = json["data"]
    }

    /**
     Subscript to get data from json with its name
     */
    subscript(name: String) -> JSON {
        return data[name]
    }
}

/**
 Place data type from munch-core/service-places
 */
struct Place: SearchResult, Equatable {
    var id: String?

    // Basic
    var name: String?
    var phone: String?
    var website: String?
    var description: String?

    // One
    var price: Price?
    var location: Location
    var review: Review?
    var tag: Tag

    // Many
    var hours: [Hour]?
    var images: [SourcedImage]?

    init?(json: JSON) {
        guard json.exists() else {
            return nil
        }

        self.id = json["id"].string

        self.name = json["name"].string
        self.phone = json["phone"].string
        self.website = json["website"].string
        self.description = json["description"].string

        self.price = Price(json: json["price"])
        self.location = Location(json: json["location"])
        self.review = Review(json: json["review"])
        self.tag = Tag(json: json["tag"])

        self.hours = json["hours"].flatMap({ Hour(json: $0.1) })
        self.images = json["images"].map({ SourcedImage(json: $0.1) })
    }

    struct Price {
        var lowest: Double?
        var middle: Double?
        var highest: Double?

        init() {

        }

        init?(json: JSON) {
            guard json.exists() else {
                return nil
            }

            self.lowest = json["lowest"].double
            self.middle = json["middle"].double
            self.highest = json["highest"].double
        }
    }

    struct Location {
        var street: String?
        var address: String?
        var unitNumber: String?

        var landmarks: [Landmark]?

        var neighbourhood: String?
        var city: String?
        var country: String?

        var postal: String?
        var latLng: String?

        init() {

        }

        init(json: JSON) {
            self.street = json["street"].string
            self.address = json["address"].string
            self.unitNumber = json["unitNumber"].string

            self.landmarks = json["landmarks"].flatMap({ Landmark(json: $0.1) })

            self.neighbourhood = json["neighbourhood"].string
            self.city = json["city"].string
            self.country = json["country"].string

            self.postal = json["postal"].string
            self.latLng = json["latLng"].string
        }

        func toParams() -> Parameters {
            // This is not completed
            var params = Parameters()
            params["street"] = street
            params["address"] = address
            params["unitNumber"] = unitNumber

            params["neighbourhood"] = neighbourhood
            params["city"] = city
            params["country"] = country

            params["postal"] = postal
            params["latLng"] = latLng
            return params
        }

        struct Landmark {
            var name: String?
            var type: String?
            var latLng: String?

            init() {

            }

            init(json: JSON) {
                self.name = json["name"].string
                self.type = json["type"].string
                self.latLng = json["latLng"].string
            }
        }
    }

    struct Review {
        var total: Int
        var average: Double

        init?(json: JSON) {
            guard json.exists() else {
                return nil
            }

            self.total = json["total"].int ?? 0
            self.average = json["average"].double ?? 0
        }
    }

    struct Tag {
        var explicits: [String]
        var implicits: [String]

        init(json: JSON) {
            self.explicits = json["explicits"].map({ $0.1.stringValue })
            self.implicits = json["implicits"].map({ $0.1.stringValue })
        }
    }

    /**
     Hour data type from munch-core/service-places
     Day can be either of these: mon, tue, wed, thu, fri, sat, sun, ph, evePh
     open, close time is in HH:mm format
     */
    struct Hour {
        let day: String
        let open: String
        let close: String

        init?(json: JSON) {
            if let day = json["day"].string, let open = json["open"].string, let close = json["close"].string {
                self.day = day
                self.open = open
                self.close = close
            } else {
                return nil
            }
        }

        func timeText() -> String {
            return Formatter.parse(open: open, close: close)
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

            class func dayNow() -> String {
                return instance.dayFormatter.string(from: Date())
            }

            class func day(addingDay day: Int = 0) -> String {
                let dateTmr = Calendar.current.date(byAdding: .day, value: day, to: Date())
                return instance.dayFormatter.string(from: dateTmr!)
            }

            class func timeAs(int time: String) -> Int? {
                return Int(time.replacingOccurrences(of: ":", with: ""))
            }

            class func isBetween(hour: Place.Hour, date: Date, opening: Int = 0, closing: Int = 0) -> Bool {
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
                let currentHours = hours.filter {
                    $0.day == currentDay
                }

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

    /**
     Check whether place is open now based on hours in Place
     */
    func isOpen() -> Hour.Formatter.Open {
        if let hours = hours {
            return Hour.Formatter.isOpen(hours: hours)
        }
        return .none
    }

    func toParams() -> Parameters {
        // This is not completed
        var params = Parameters()
        params["id"] = id
        params["name"] = name
        params["location"] = location.toParams()
        params["dataType"] = "Place"
        return params
    }

    static func ==(lhs: Place, rhs: Place) -> Bool {
        if (lhs.id == nil || rhs.id == nil) {
            return false
        }
        return lhs.id == rhs.id
    }
}

/**
 BusinessHour
 */
class BusinessHour {
    let hours: [Place.Hour]
    let dayHours: [String: String]

    init(hours: [Place.Hour]) {
        self.hours = hours

        var dayHours = [String: String]()
        for hour in hours.sorted(by: { $0.open < $1.open }) {
            if let timeText = dayHours[hour.day] {
                dayHours[hour.day] = timeText + ", " + hour.timeText()
            } else {
                dayHours[hour.day] = hour.timeText()
            }
        }
        self.dayHours = dayHours
    }

    subscript(day: String) -> String {
        get {
            return dayHours[day] ?? "Closed"
        }
    }

    func isToday(day: String) -> Bool {
        return day == Place.Hour.Formatter.dayNow().lowercased()
    }

    func isOpen() -> Place.Hour.Formatter.Open {
        return Place.Hour.Formatter.isOpen(hours: hours)
    }

    var today: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayInWeek = dateFormatter.string(from: Date())
        return dayInWeek.capitalized + ": " + self.todayTime
    }

    var todayTime: String {
        return self[Place.Hour.Formatter.dayNow().lowercased()]
    }
}

/**
 Primary data type from munch-core/service-articles
 */
struct Article {
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

    init(json: JSON) {
        self.articleId = json["articleId"].string
        self.articleListNo = json["articleListNo"].string

        self.placeId = json["placeId"].string
        self.placeSort = json["placeSort"].string
        self.placeName = json["placeName"].string

        self.url = json["url"].string
        self.brand = json["brand"].string
        self.title = json["title"].string
        self.description = json["description"].string

        self.thumbnail = json["thumbnail"].dictionaryObject as? [String: String]
    }
}

struct InstagramMedia {
    var userId: String?
    var mediaId: String?

    var locationId: String?

    var placeId: String?
    var placeSort: String?
    var placeName: String?

    var type: String?
    var caption: String?
    var username: String?
    var profilePicture: String?

    var images: [String: String]?

    init(json: JSON) {
        self.userId = json["userId"].string
        self.mediaId = json["mediaId"].string

        self.locationId = json["locationId"].string

        self.placeId = json["placeId"].string
        self.placeSort = json["placeSort"].string
        self.placeName = json["placeName"].string

        self.type = json["type"].string
        self.caption = json["caption"].string
        self.username = json["username"].string
        self.profilePicture = json["profilePicture"].string

        self.images = json["images"].dictionaryObject as? [String: String]
    }
}

/**
 Menu data type from munch-core/service-menus
 */
struct Menu {
    let placeId: String
    let menuId: String
}

/**
 SourcedImage from munch-core/munch-data
 */
struct SourcedImage {
    var source: String
    var sourceId: String?
    var sourceName: String?
    var images: [String: String]

    init(json: JSON) {
        self.source = json["source"].stringValue
        self.sourceId = json["sourceId"].string
        self.sourceName = json["sourceName"].string
        self.images = json["images"].dictionaryObject as! [String: String]
    }
}