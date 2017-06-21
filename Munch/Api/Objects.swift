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
struct Place {
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
    }
    
    struct Price {
        var lowest: Double?
        var highest: Double?
        
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
        
        init(json: JSON) {
            self.address = json["address"].string
            self.unitNumber = json["unitNumber"].string
            
            self.city = json["city"].string
            self.country = json["country"].string
            
            self.postal = json["postal"].string
            self.latLng = json["latLng"].string
        }
        
    }
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
struct SearchQuery {
    static let d2r = Double.pi / 180.0
    static let r2d = 180 / Double.pi
    static let earthRadius = 6371.0
    
    var from: Int?
    var size: Int?
    
    var query: String?
    var polygon: Polygon?

    init() {
        
    }
    
    init(json: JSON) {
        self.from = json["from"].int
        self.size = json["size"].int
        
        self.query = json["query"].string
        
        if (json["polygon"].exists()){
            self.polygon = Polygon(json: json["polygon"])
        }
    }
    
    struct Polygon {
        var points: [String]
        
        init(json: JSON) {
            self.points = json["points"].map({$0.1.stringValue})
        }
        
        init(lat: Double, lng: Double, radius: Double, size: Int) {
            let rlat = radius / earthRadius * r2d
            let rlng = rlat / cos(lat * d2r)
            
            // Create Points in latLng String array
            points = [String]()
            
            // Create all points for polygon circle with n size
            for i in 0...size-1 {
                let theta = Double.pi * (Double(i) / (Double(size)/2))
                let ex = lng + (rlng * cos(theta))
                let ey = lat + (rlat * sin(theta))
                points.append("\(ey),\(ex)")
            }

        }
    }
    
    struct Filters {
        // TODO in the Future once finalized
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
            params["query"] = poly
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
    
    init() {
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        inFormatter.dateFormat = "HH:mm"
        
        outFormatter.locale = Locale(identifier: "en_US_POSIX")
        outFormatter.dateFormat = "h:mma"
        outFormatter.amSymbol = "am"
        outFormatter.pmSymbol = "pm"
    }
    
    /**
     Accepts: Time in String
     Format time to 10:00am
    */
    func format(string: String) -> String {
        let date = inFormatter.date(from: string)
        return outFormatter.string(from: date!)
    }
    
    /**
     Accepts: Hour
     Format hour open to String: 10:00am - 3:00pm
    */
    class func format(hour: Hour) -> String {
        let open = instance.format(string: hour.open!)
        let close = instance.format(string: hour.close!)
        return "\(open) - \(close)"
    }
    
    /**
     Accepts: Array of Hour
     Format hours to packed: "Mon - Fri: 10:00am - 3:00pm" joined by \n
    */
    class func format(hours: [Hour]) -> String {
        let sorted = hours.sorted(by: {daysOrder[$0.0.day!]! < daysOrder[$0.1.day!]!})
        var lines = [String]()
        var tuple: (String, String, String)! = nil
        
        func make() -> String {
            if (tuple.1 == tuple.2) {
                return "\(tuple.1): \(tuple.0)"
            } else {
                return "\(tuple.1) - \(tuple.2): \(tuple.0)"
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
 Hour data type from munch-core/service-places
 Day can be either of these: mon, tue, wed, thu, fri, sat, sun, ph, evePh
 open, close time is in HH:mm format
 
 TODO improve with enum type for day
 */
struct Hour {
    var day: String?
    var open: String?
    var close: String?
    
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

/**
 Primary data type from munch-core/service-gallery
 it is a version of Instagram Media
 */
struct Media {
    var placeId: String?
    var mediaId: String?
    
    var profile: Profile?
    var caption: String?
    var images: [String: Image]?
    
    init(json: JSON) {
        self.placeId = json["placeId"].string
        self.mediaId = json["mediaId"].string
        
        self.profile = Profile(json: json["profile"])
        self.caption = json["caption"].string
        self.images = json["images"].reduce([String:Image]()) { (result, json) -> [String: Image] in
            var result = result
            result[json.0] = Image(json: json.1)
            return result
        }
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
    
    struct Image {
        var url: String?
        var width: Int?
        var height: Int?
        
        init(json: JSON) {
            self.url = json["url"].string
            self.width = json["width"].int
            self.height = json["height"].int
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
    var images: [Image]?

    
    init(json: JSON) {
        self.placeId = json["placeId"].string
        self.articleId = json["articleId"].string
        
        self.brand = json["brand"].string
        self.url = json["url"].string
        
        self.title = json["title"].string
        self.description = json["description"].string
        self.images = json["images"].map({Image(json: $0.1)})
    }
    
    /**
     Image structure unique to Article image type only
    */
    struct Image {
        var url: String?
        var key: String?
        var images: [String: String]
        
        init(json: JSON) {
            self.url = json["url"].string
            self.key = json["key"].string
            self.images = json["images"].reduce([String:String]()) { (result, json) -> [String: String] in
                var result = result
                result[json.0] = json.1["url"].string
                return result
            }

        }
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
    
    init(json: JSON) {
        self.key = json["key"].string
        self.images = json["images"].reduce([String:String]()) { (result, json) -> [String: String] in
            var result = result
            result[json.0] = json.1["url"].string
            return result
        }
    }
}
