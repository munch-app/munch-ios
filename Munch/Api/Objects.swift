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
        
        self.tags = json["tags"].map { $0.1.stringValue }
        self.hours = json["hours"].map { Hour(json: $0.1) }
        self.images = json["images"].map { ImageMeta(json: $0.1) }
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
 Location object form munch-core/service-location
 Used in search for munch-core/service-places
 */
struct Location: SearchResult {
    var name: String?
    var city: String?
    var country: String?
    
    var center: String?
    var points: [String]? // points is ["lat, lng"] String Array
    
    init?(json: JSON) {
        if (!json.exists()) { return nil }
    
        self.name = json["name"].string
        self.city = json["city"].string
        self.country = json["country"].string
        
        self.center = json["center"].string
        self.points = json["points"].map({$0.1.stringValue})
    }
    
    func toParams() -> Parameters {
        var params = Parameters()
        params["name"] = name
        params["city"] = city
        params["country"] = country
        
        params["center"] = center
        params["points"] = points
        return params
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
    
    init?(json: JSON) {
        if (!json.exists()) { return nil }
        self.place = Place(json: json["place"])
        self.medias = json["medias"].map({Media(json: $0.1)})
        self.articles = json["articles"].map({Article(json: $0.1)})
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
public struct SearchQuery: Equatable {
    var from: Int?
    var size: Int?
    
    var query: String?
    var location: Location?
    
    // These types should never be nil
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
        self.location = Location(json: json["location"])
        
        self.filter = Filter(json: json["filter"])
        self.sort = Sort(json: json["sort"])
    }
    
    public struct Filter {
        var price = Price()
        var tag = Tag()
        var rating = Rating()
        var hour = Hour()
        var distance = Distance()
        
        init() {
            
        }
        
        init(json: JSON) {
            price.min = json["price"]["min"].double
            price.max = json["price"]["max"].double
            
            tag.positives = json["tag"]["positives"].arrayValue.map { $0.stringValue }
            tag.negatives = json["tag"]["negatives"].arrayValue.map { $0.stringValue }
            
            rating.min = json["rating"]["min"].double
            
            distance.latLng = json["distance"]["latLng"].string
            distance.max = json["distance"]["max"].int
        }
        
        public struct Price {
            var min: Double?
            var max: Double?
            
        }
        
        public struct Tag {
            var positives: [String]?
            var negatives: [String]?
        }
        
        public struct Rating {
            var min: Double?
        }
        
        public struct Hour {
            
        }
        
        public struct Distance {
            var latLng: String?
            var max: Int? // In metres
        }
        
        public func toParams() -> Parameters {
            var params = Parameters()
            params["price"] = ["min": price.min, "max": price.max]
            params["tag"] = ["positives": tag.positives, "negatives": tag.negatives]
            params["rating"] = ["min": rating.min]
            
            var distanceParams = Parameters()
            distanceParams["latLng"] = distance.latLng
            distanceParams["max"] = distance.max
            params["distance"] = distanceParams
            return params
        }
    }
    
    public struct Sort {
        var distance = Distance()
        
        init() {
            
        }
        
        init(json: JSON) {
            distance.latLng = json["distance"]["latLng"].string
        }
        
        public struct Distance {
            var latLng: String?
        }
        
        public func toParams() -> Parameters {
            var params = Parameters()
            params["distance"] = ["latLng": distance.latLng]
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
    
    public static func == (lhs: SearchQuery, rhs: SearchQuery) -> Bool {
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
    func format(time: String) -> String {
        let date = inFormatter.date(from: time)
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
    func format(hour: Place.Hour) -> String {
        let open = format(time: hour.open!)
        let close = format(time: hour.close!)
        return "\(open) - \(close)"
    }
    
    class func format(hours: [Place.Hour]) -> String? {
        if (hours.isEmpty) { return nil }
        
        // Sort by open time and days in asc order
        let sorted = hours.sorted(by: { $0.0.open! <  $0.1.open! })
            .sorted(by: {daysOrder[$0.0.day!]! < daysOrder[$0.1.day!]!})
        
        // Compact into day lines, (day, time)
        var dayLines: [(String, String)] = []
        for hour in sorted {
            if dayLines.last?.0 == hour.day {
                let last = dayLines.popLast()
                dayLines.append((hour.day!, "\(last!.1 ), \(instance.format(hour: hour))"))
            } else {
                // Else add new line
                dayLines.append((hour.day!, instance.format(hour: hour)))
            }
        }
        
        // Compact days into smaller lines if similar, (day, day, time)
        var rangeLines: [(String, String, String)] = []
        for dayLine in dayLines {
            if (rangeLines.last?.2 == dayLine.1) {
                let last = rangeLines.popLast()
                rangeLines.append((last!.0, dayLine.0, dayLine.1))
            } else {
                rangeLines.append((dayLine.0, dayLine.0, dayLine.1))
            }
        }
        
        // If first and last are the same, join them
//        if (rangeLines.count > 2) {
//            if (rangeLines.first?.2 == rangeLines.last?.2) {
//                let last = rangeLines.popLast()
//                let first = rangeLines.first
//                first?.0
//            }
//        }
        return rangeLines.map({
            if ($0.0 == $0.1) {
                return "\($0.0.capitalized): \($0.2)"
            } else {
                return "\($0.0.capitalized) - \($0.1.capitalized): \($0.2)"
            }
        }).joined(separator: "\n")
    }
    
    /**
     Accepts: Array of Hour
     Format hours to packed: "Mon - Fri: 10:00am - 3:00pm" joined by \n
    */
//    class func format(hours: [Place.Hour]) -> String? {
//        if (hours.isEmpty) { return nil }
//        
//        // Sorted opening hours
//        let sorted = hours.sorted(by: {daysOrder[$0.0.day!]! < daysOrder[$0.1.day!]!})
//        var lines = [String]()
//        var tuple: (String, String, String)! = nil
//        
//        func make() -> String {
//            if (tuple.1 == tuple.2) {
//                return "\(tuple.1.capitalized): \(tuple.0)"
//            } else {
//                return "\(tuple.1.capitalized) - \(tuple.2.capitalized): \(tuple.0)"
//            }
//        }
//        
//        for hour in sorted {
//            if (tuple == nil) {
//                tuple = (hour.rangeText(), hour.day!, hour.day!)
//            } else {
//                if (tuple.0 == hour.rangeText() && (daysOrder[tuple.2]! + 1) == daysOrder[hour.day!]) {
//                    tuple.2 = hour.day!
//                }else{
//                    lines.append(make())
//                    tuple = (hour.rangeText(), hour.day!, hour.day!)
//                }
//            }
//        }
//        lines.append(make())
//        return lines.joined(separator: "\n")
//    }
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


