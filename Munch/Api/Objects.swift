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
    var images: [Image]?
    
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
 Basic and Vendor typed Cards
 Access json through the subscript
 */
struct PlaceCard {
    var id: String
    private var json: JSON
    
    init(id: String) {
        self.id = id
        self.json = JSON(parseJSON: "{}")
    }
    
    init(json: JSON) {
        self.id = json["id"].stringValue
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
 Location object form munch-core/service-location
 Used in search for munch-core/service-places
 */
struct Location: SearchResult {
    var id: String?
    var name: String?
    var city: String?
    var country: String?
    
    var center: String?
    var points: [String]? // points is ["lat, lng"] String Array
    
    init?(json: JSON) {
        if (!json.exists()) { return nil }
    
        self.id = json["id"].string
        self.name = json["name"].string
        self.city = json["city"].string
        self.country = json["country"].string
        
        self.center = json["center"].string
        self.points = json["points"].map({$0.1.stringValue})
    }
    
    func toParams() -> Parameters {
        var params = Parameters()
        params["id"] = id
        params["name"] = name
        params["city"] = city
        params["country"] = country
        
        params["center"] = center
        params["points"] = points
        return params
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
 */
struct SearchQuery: Equatable {
    var from: Int?
    var size: Int?
    
    var query: String?
    var latLng: String?
    var location: Location?
    
    var filter: Filter
    var sort: Sort
    
    init() {
        filter = Filter()
        sort = Sort()
    }
    
    init(json: JSON) {
        self.from = json["from"].int
        self.size = json["size"].int
        
        self.query = json["query"].string
        self.latLng = json["latLng"].string
        self.location = Location(json: json["location"])
        
        self.filter = Filter(json: json["filter"])
        self.sort = Sort(json: json["sort"])
    }
    
    struct Filter {
        var price = Price()
        var tag = Tag()
        var hour = Hour()
        
        init() {
            
        }
        
        init(json: JSON) {
            price.min = json["price"]["min"].double
            price.max = json["price"]["max"].double
            
            tag.positives = json["tag"]["positives"].arrayValue.map { $0.stringValue }
            tag.negatives = json["tag"]["negatives"].arrayValue.map { $0.stringValue }
        
            hour.day = json["hour"]["day"].string
            hour.time = json["hour"]["time"].string
            
        }
        
        struct Price {
            var min: Double?
            var max: Double?
            
        }
        
        struct Tag {
            var positives: [String]?
            var negatives: [String]?
        }
        
        struct Hour {
            var day: String?
            var time: String?
        }
        
        func toParams() -> Parameters {
            var params = Parameters()
            params["price"] = ["min": price.min, "max": price.max]
            params["tag"] = ["positives": tag.positives, "negatives": tag.negatives]
            params["hour"] = ["day": hour.day, "time": hour.time]
            return params
        }
    }
    
    struct Sort {
        // See MunchCore for the available sort methods
        var type: String?
        
        init() {
            
        }
        
        init(json: JSON) {
            type = json["sort"]["type"].string
        }
        
        func toParams() -> Parameters {
            var params = Parameters()
            params["type"] = type
            return params
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
        params["location"] = location?.toParams()
        
        params["filter"] = filter.toParams()
        params["sort"] = sort.toParams()
        return params
    }
    
    static func == (lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        return NSDictionary(dictionary: lhs.toParams()).isEqual(to: rhs.toParams())
    }
}

/**
 SearchCollection object from munch-core/munch-api
 used for containing a collection
 */
struct SearchCollection {
    let name: String
    let query: SearchQuery
    let results: [SearchResult]
    
    init(json: JSON) {
        self.name = json["name"].stringValue
        self.query = SearchQuery(json: json["query"])
        self.results = SearchCollection.parseList(searchResult: json["results"])
    }
    
    init(name: String, query: SearchQuery, results: [CardItem]){
        self.name = name
        self.query = query
        self.results = results
    }
    
    /**
     Method to parse search result type
     */
    public static func parse(searchResult json: JSON) -> SearchResult? {
        switch json["type"].stringValue {
        case "Place": return Place(json: json)
        case "Location": return Location(json: json)
        default: return nil
        }
    }
    
    /**
     Parse only search item
     */
    public static func parseList(searchResult json: JSON) -> [SearchResult] {
        var results = [SearchResult]()
        for each in json {
            if let item = parse(searchResult: each.1) {
                results.append(item)
            }
        }
        return results
    }
}

/**
 Possible types are:
 - Place
 - Location
 */
protocol SearchResult {
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
    let images: [String: String]
    
    init(images: [String: String]) {
        self.images = images
    }
    
    init(json: JSON) {
        self.key = json["key"].string
        self.images = json["images"].reduce([String:String]()) { (result, json) -> [String: String] in
            var result = result
            result[json.0] = json.1.string
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


