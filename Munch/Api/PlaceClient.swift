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
    
    func cards(id: String, callback: @escaping (_ meta: MetaJSON, _ cards: [PlaceCard]) -> Void) {
        MunchApi.restful.get("/places/\(id)/cards") { meta, json in
            callback(meta, json["data"].map { PlaceCard(json: $0.1) })
        }
    }
}

/**
 Basic and Vendor typed Cards
 Access json through the subscript
 */
struct PlaceCard {
    var cardId: String
    private var json: JSON
    
    init(cardId: String) {
        self.cardId = cardId
        self.json = JSON(parseJSON: "{}")
    }
    
    init(json: JSON) {
        self.cardId = json["_cardId"].stringValue
        self.json = json
    }
    
    /**
     Subscript to get data from json with its name
     */
    subscript(name: String) -> JSON {
        return json[name]
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
    var location: Location?
    
    // Many
    var tags: [String]?
    var hours: [Hour]?
    var images: [Image]?
    
    init(json: JSON){
        self.id = json["id"].string
        
        self.name = json["name"].string
        self.phone = json["phone"].string
        self.website = json["website"].string
        self.description = json["description"].string
        
        self.price = Price(json: json["price"])
        self.location = Location(json: json["location"])
        
        self.tags = json["tags"].map { $0.1.stringValue }
        self.hours = json["hours"].flatMap { Hour(json: $0.1) }
        self.images = json["images"].map { Image(json: $0.1) }
    }
    
    struct Price {
        var lowest: Double?
        var highest: Double?
        
        init() {
            
        }
        
        init(json: JSON){
            self.lowest = json["lowest"].double
            self.highest = json["highest"].double
        }
    }
    
    struct Location {
        var street: String?
        var address: String?
        var unitNumber: String?
        var building: String?
        
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
            
            self.city = json["city"].string
            self.country = json["country"].string
            
            self.postal = json["postal"].string
            self.latLng = json["latLng"].string
        }
    }
    
    /**
     Place.Image from munch-core/munch-data
     */
    struct Image {
        var source: String?
        var imageMeta: ImageMeta?
        
        init(json: JSON) {
            self.source = json["source"].string
            self.imageMeta = ImageMeta(json: json["imageMeta"])
        }
    }
    
    /**
     Hour data type from munch-core/service-places
     Day can be either of these: mon, tue, wed, thu, fri, sat, sun, ph, evePh
     open, close time is in HH:mm format
     
     TODO improve with enum type for day
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
            
            class func isBetween(hour: Place.Hour, date: Date) -> Bool {
                let now = Int(instance.inFormatter.string(from: date).replacingOccurrences(of: ":", with: ""))
                let open = Int(hour.open.replacingOccurrences(of: ":", with: ""))
                let close = Int(hour.close.replacingOccurrences(of: ":", with: ""))
                
                if let open = open, let close = close, let now = now {
                    return open < now && now < close
                }
                return false
            }
            
            class func isOpen(hours: [Hour]) -> Bool? {
                if (hours.isEmpty) { return nil }
                
                let date = Date()
                let day = dayNow().lowercased()
                let todays = hours.filter { $0.day == day }
                
                for today in todays {
                    if (isBetween(hour: today, date: date)) {
                        return true
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
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        if (lhs.id == nil || rhs.id == nil) {
            return false
        }
        return lhs.id == rhs.id
    }
}

/**
 Primary data type from munch-core/service-gallery
 it is a version of Instagram Media
 */
struct Media {
    var placeId: String?
    var mediaId: String?
    
    var profile: Profile?
    var caption: String?
    var image: ImageMeta?
    
    init(json: JSON) {
        self.placeId = json["placeId"].string
        self.mediaId = json["mediaId"].string
        
        self.profile = Profile(json: json["profile"])
        self.caption = json["caption"].string
        self.image = ImageMeta(json: json["image"])
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
    var placeId: String?
    var articleId: String?
    
    var brand: String?
    var url: String?
    
    var title: String?
    var description: String?
    var thumbnail: ImageMeta?
    
    init(json: JSON) {
        self.placeId = json["placeId"].string
        self.articleId = json["articleId"].string
        
        self.brand = json["brand"].string
        self.url = json["url"].string
        
        self.title = json["title"].string
        self.description = json["description"].string
        self.thumbnail = ImageMeta(json: json["thumbnail"])
    }
}

/**
 Menu data type from munch-core/service-menus
 */
struct Menu {
    let placeId: String
    let menuId: String
}
