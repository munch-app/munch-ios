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

    func cards(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place?, _ cards: [PlaceCard]) -> Void) {
        MunchApi.restful.get("/places/\(id)/cards") { meta, json in
            callback(meta,
                    Place(json: json["data"]["place"]),
                    json["data"]["cards"].map({ PlaceCard(json: $0.1) })
            )
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
    var tag: Tag

    // Many
    var hours: [Hour]?
    var images: [Image]?

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
        self.tag = Tag(json: json["tag"])

        self.hours = json["hours"].flatMap {
            Hour(json: $0.1)
        }
        self.images = json["images"].map {
            Image(json: $0.1)
        }
    }

    struct Price {
        var lowest: Double?
        var middle: Double?
        var highest: Double?

        init() {

        }

        init(json: JSON) {
            self.lowest = json["lowest"].double
            self.middle = json["middle"].double
            self.highest = json["highest"].double
        }
    }

    struct Location {
        var street: String?
        var address: String?
        var unitNumber: String?
        var building: String?
        var nearestTrain: String?

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
            self.building = json["building"].string
            self.nearestTrain = json["nearestTrain"].string

            self.city = json["city"].string
            self.country = json["country"].string

            self.postal = json["postal"].string
            self.latLng = json["latLng"].string
        }
    }

    struct Tag {
        var explicits: [String]
        var implicits: [String]

        init(json: JSON) {
            self.explicits = json["explicits"].map {
                $0.1.stringValue
            }
            self.implicits = json["implicits"].map {
                $0.1.stringValue
            }
        }
    }

    /**
     Place.Image from munch-core/munch-data
     */
    struct Image {
        var source: String
        var images: [String: String]

        init(json: JSON) {
            self.source = json["source"].stringValue
            self.images = json["images"].dictionaryObject as! [String: String]
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

            class func isBetween(hour: Place.Hour, date: Date) -> Bool {
                let now = timeAs(int: instance.inFormatter.string(from: date))!
                let open = timeAs(int: hour.open)
                let close = timeAs(int: hour.close)

                if let open = open, let close = close {
                    if (close < open) {
                        return open <= now && now <= 2400
                    }
                    return open <= now && now <= close
                }
                return false
            }

            class func isOpen(hours: [Hour]) -> Bool? {
                if (hours.isEmpty) {
                    return nil
                }

                let date = Date()
                let now = timeAs(int: instance.inFormatter.string(from: date))!
                let currentDay = day().lowercased()
                let currentHours = hours.filter {
                    $0.day == currentDay
                }

                for hour in currentHours {
                    if (isBetween(hour: hour, date: date)) {
                        return true
                    }
                }

                let ytdDay = day(addingDay: -1).lowercased()
                let ytdHours = hours.filter {
                    $0.day == ytdDay
                }
                for hour in ytdHours {
                    let open = timeAs(int: hour.open)
                    let close = timeAs(int: hour.close)
                    if let open = open, let close = close {
                        if (close < open) {
                            return 0 <= now && now <= close
                        }
                    }
                }
                return false
            }
        }
    }

    /**
     Check whether place is open now based on hours in Place
     */
    func isOpen() -> Bool? {
        if let hours = hours {
            return Hour.Formatter.isOpen(hours: hours)
        }
        return nil
    }

    func toParams() -> Parameters {
        // This is not completed
        var params = Parameters()
        params["id"] = id
        params["name"] = name
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
 Instagram Media
 */
struct InstagramMedia {
    var placeId: String?
    var mediaId: String?

    var profile: Profile?
    var caption: String?

    init(json: JSON) {
        self.placeId = json["placeId"].string
        self.mediaId = json["mediaId"].string

        self.profile = Profile(json: json["profile"])
        self.caption = json["caption"].string
    }

    struct Profile {
        var userId: String?
        var username: String?
        var pictureUrl: String?

        init(json: JSON) {
            self.userId = json["userId"].string
            self.username = json["username"].string
            self.pictureUrl = json["pictureUrl"].string
        }
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

/**
 Menu data type from munch-core/service-menus
 */
struct Menu {
    let placeId: String
    let menuId: String
}
