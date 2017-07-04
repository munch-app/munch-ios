//
//  Place.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

/**
 Place data type from munch-core/service-places
 */
struct Place: CardItem, Equatable {
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
    var images: [ImageMeta]?
    
    init() {
        
    }
    
    init(json: JSON){
        self.id = json["id"].string
        
        self.name = json["name"].string
        self.phone = json["phone"].string
        self.website = json["website"].string
        self.description = json["description"].string
        
        self.price = Price(json: json["price"])
        self.location = Location(json: json["location"])
        
        self.tags = json["tags"].map({$0.1.stringValue})
        self.hours = json["hours"].map({Hour(json: $0.1)})
        self.images = json["images"].map({ImageMeta(json: $0.1)})
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
        var address: String?
        var unitNumber: String?
        
        var city: String?
        var country: String?
        
        var postal: String?
        var latLng: String?
        
        init() {
            
        }
        
        init(json: JSON) {
            self.address = json["address"].string
            self.unitNumber = json["unitNumber"].string
            
            self.city = json["city"].string
            self.country = json["country"].string
            
            self.postal = json["postal"].string
            self.latLng = json["latLng"].string
        }
    }
    
    /**
     Hour data type from munch-core/service-places
     Day can be either of these: mon, tue, wed, thu, fri, sat, sun, ph, evePh
     open, close time is in HH:mm format
     
     TODO improve with enum type for day
     */
    struct Hour {
        var day: String?
        var open: String?
        var close: String?
        
        init() {
            
        }
        
        init(json: JSON) {
            self.day = json["day"].string
            self.open = json["open"].string
            self.close = json["close"].string
        }
        
        func rangeText() -> String {
            return HourFormatter.format(hour: self)
        }
        
        func dayText() -> String {
            if (day == "evePh"){
                return "Eve of Ph"
            }
            return day!.capitalized
        }
    }
    
    func isOpen() -> Bool? {
        if let hours = hours {
            let date = Date()
            let day = HourFormatter.instance.dayNow().lowercased()
            let todays = hours.filter { $0.day == day }
            for today in todays {
                if let open = HourFormatter.instance.isBetween(hour: today, date: date) {
                    if (open) { return true }
                }
            }
            return false
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
 Menu data type from munch-core/service-menus
 */
struct Menu {
    let placeId: String
    let menuId: String
}

/**
 SearchQuery object from munch-core/service-places
 This is a input and output data
 
 - from: pagination from
 - size: pagination size
 - query: search query string
 - polygon: { points: [String] }
 
 - filters: to be implemented in the future
 */
public struct SearchQuery {
    var from: Int?
    var size: Int?
    
    var query: String?
    var polygon: Polygon?
    var filters: Filters?
    
    init() {
        
    }
    
    init(json: JSON) {
        self.from = json["from"].int
        self.size = json["size"].int
        
        self.query = json["query"].string
        
        if (json["polygon"].exists()) {
            self.polygon = Polygon(json: json["polygon"])
        }
        
        if (json["filters"].exists()) {
            self.filters = Filters(json: json["filters"])
        }
    }
    
    public struct Polygon {
        private static let d2r = Double.pi / 180.0
        private static let r2d = 180 / Double.pi
        private static let earthRadius = 6371.0
        
        var points: [String]
        
        init(json: JSON) {
            self.points = json["points"].map({$0.1.stringValue})
        }
        
        /**
         radius is in KM
         */
        init(lat: Double, lng: Double, radius: Double, size: Int) {
            let rlat = radius / Polygon.earthRadius * Polygon.r2d
            let rlng = rlat / cos(lat * Polygon.d2r)
            
            // Create Points in latLng String array
            points = [String]()
            
            // Create all points for polygon circle with n size
            for i in 0..<size {
                let theta = Double.pi * (Double(i) / (Double(size)/2))
                let ex = lng + (rlng * cos(theta))
                let ey = lat + (rlat * sin(theta))
                points.append("\(ey),\(ex)")
            }

        }
    }
    
    public struct Filters {
        // TODO priceRange & hours
        var tags: [Tag]?
        var ratingsAbove: Double?
        
        init(json: JSON) {
            self.tags = json["tags"].map {Tag(json: $0.1)}
            self.ratingsAbove = json["ratingsAbove"].double
        }
        
        public struct Tag {
            var text: String?
            var positive: Bool?
            
            init(json: JSON) {
                self.text = json["text"].string
                self.positive = json["positive"].bool
            }
        }
    }
    
    /**
     Map to Alamofire supported parameters encoding
     */
    func toParams() -> Parameters {
        var params = Parameters()
        params["from"] = from
        params["size"] = size
        params["query"] = query
        
        if let polygon = polygon {
            var poly = Parameters()
            poly["points"] = polygon.points
            params["polygon"] = poly
        }
        
        if let filters = filters {
            var filt = Parameters()
            filt["ratingsAbove"] = filters.ratingsAbove
            if let tags = filters.tags {
                let tagArray: [Parameters] = tags.map { data -> Parameters in
                    var tag = Parameters()
                    tag["text"] = data.text
                    tag["positive"] = data.positive
                    return tag
                }
                filt["tags"] = tagArray
            }
            params["filters"] = filt
        }
        return params
    }
}

/**
 Location object form munch-core/service-location
 Used in search for munch-core/service-places
 */
struct Location {
    let name: String
    let center: String
    let points: [String] // points is ["lat, lng"] String Array
    
    init(json: JSON) {
        self.name = json["name"].stringValue
        self.center = json["center"].stringValue
        self.points = json["points"].map({$0.1.stringValue})
    }
}

/**
 PlaceDetail object from munch-core/service-places
 Used to to send place, medias, articles and review in one object
 */
struct PlaceDetail {
    let place: Place
    let medias: [Media]
    let articles: [Article]
    
    init(json: JSON) {
        self.place = Place(json: json["place"])
        self.medias = json["medias"].map({Media(json: $0.1)})
        self.articles = json["articles"].map({Article(json: $0.1)})
    }
}

/**
 PlaceCollection object from munch-core/service-places
 used for containing a collection
 */
struct PlaceCollection {
    let name: String
    let query: SearchQuery
    let places: [Place]
    
    init(json: JSON) {
        self.name = json["name"].stringValue
        self.query = SearchQuery(json: json["query"])
        self.places = json["places"].map({Place(json: $0.1)})
    }
    
    init(name: String, query: SearchQuery, places: [Place]){
        self.name = name
        self.query = query
        self.places = places
    }
}

/**
 Format hour in String
 Example:
 Mon - Fri: 11:00am - 8:00pm
 Sat - Sun: 12:00am - 10:00pm
 */
class HourFormatter {
    static let instance = HourFormatter()
    static let daysOrder = [
        "mon": 1,
        "tue": 2,
        "wed": 3,
        "thu": 4,
        "fri": 5,
        "sat": 6,
        "sun": 7,
        "ph": 100,
        "evePh": 1000
    ]
    
    let inFormatter = DateFormatter()
    let outFormatter = DateFormatter()
    let dayFormatter = DateFormatter()
    
    init() {
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        inFormatter.dateFormat = "HH:mm"
        
        outFormatter.locale = Locale(identifier: "en_US_POSIX")
        outFormatter.dateFormat = "h:mma"
        outFormatter.amSymbol = "am"
        outFormatter.pmSymbol = "pm"
        
        dayFormatter.dateFormat = "EEE"
    }
    
    /**
     Accepts: Time in String
     Format time to 10:00am
    */
    func format(string: String) -> String {
        let date = inFormatter.date(from: string)
        return outFormatter.string(from: date!)
    }
    
    func dayNow() -> String {
        return dayFormatter.string(from: Date())
    }
    
    func isBetween(hour: Place.Hour, date: Date) -> Bool? {
        let now = inFormatter.string(from: date).replacingOccurrences(of: ":", with: "")
        if let open = hour.open?.replacingOccurrences(of: ":", with: ""),
            let close = hour.close?.replacingOccurrences(of: ":", with: "") {
            if let openI = Int(open), let closeI = Int(close), let nowI = Int(now) {
                return openI < nowI && nowI < closeI
            }
        }
        return nil
    }
    
    /**
     Accepts: Hour
     Format hour open to String: 10:00am - 3:00pm
    */
    class func format(hour: Place.Hour) -> String {
        let open = instance.format(string: hour.open!)
        let close = instance.format(string: hour.close!)
        return "\(open) - \(close)"
    }
    
    /**
     Accepts: Array of Hour
     Format hours to packed: "Mon - Fri: 10:00am - 3:00pm" joined by \n
    */
    class func format(hours: [Place.Hour]) -> String? {
        if (hours.isEmpty) { return nil }
        let sorted = hours.sorted(by: {daysOrder[$0.0.day!]! < daysOrder[$0.1.day!]!})
        var lines = [String]()
        var tuple: (String, String, String)! = nil
        
        func make() -> String {
            if (tuple.1 == tuple.2) {
                return "\(tuple.1.capitalized): \(tuple.0)"
            } else {
                return "\(tuple.1.capitalized) - \(tuple.2.capitalized): \(tuple.0)"
            }
        }
        
        for hour in sorted {
            if (tuple == nil) {
                tuple = (hour.rangeText(), hour.day!, hour.day!)
            } else {
                if (tuple.0 == hour.rangeText() && (daysOrder[tuple.2]! + 1) == daysOrder[hour.day!]) {
                    tuple.2 = hour.day!
                }else{
                    lines.append(make())
                    tuple = (hour.rangeText(), hour.day!, hour.day!)
                }
            }
        }
        lines.append(make())
        return lines.joined(separator: "\n")
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
 ImageMeta is provided by munch-core/service-images
 structure is {
    key: "",
    images: {
        "type": {key: "", url : ""}
    }
 }
 */
struct ImageMeta {
    var key: String?
    var images: [String: String]
    
    init(images: [String: String]) {
        self.images = images
    }
    
    init(json: JSON) {
        self.key = json["key"].string
        self.images = json["images"].reduce([String:String]()) { (result, json) -> [String: String] in
            var result = result
            result[json.0] = json.1["url"].string
            return result
        }
    }
    
    func imageList() -> [(Int, Int, String)] {
        return images.map { key, value -> (Int, Int, String) in
            let widthHeight = key.lowercased().components(separatedBy: "x")
            if (widthHeight.count == 2) {
                if let width = Int(widthHeight[0]), let height = Int(widthHeight[1]) {
                    return (width, height, value)
                }
            }
            return (0, 0, value)
        }
    }
}


