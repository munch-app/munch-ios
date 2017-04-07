//
//  Place.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

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
    var establishments: [String]?
    var amenities: [String]?
    var images: [Image]?
    var menus: [Menu]?
    var hours: [Hour]?
    
    init(json: JSON){
        self.id = json["id"].string
        
        // Basic
        self.name = json["name"].string
        self.phone = json["phone"].string
        self.website = json["website"].string
        self.description = json["description"].string
        
        // One
        self.price = Price(json: json["price"])
        self.location = Location(json: json["location"])
        
        // Many
        self.establishments = json["establishments"].map({$0.1.stringValue})
        self.amenities = json["amenities"].map({$0.1.stringValue})
        self.images = json["images"].map({Image(json: $0.1)})
        self.menus = json["menus"].map({Menu(json: $0.1)})
        self.hours = json["hours"].map({Hour(json: $0.1)})
    }
    
    func imageURL() -> URL? {
        if let imageUrl = self.images?.first?.url {
            return URL(string: imageUrl)
        } else {
            return nil
        }
    }
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
    var lat: Double?
    var lng: Double?
    
    init(json: JSON) {
        self.address = json["address"].string
        self.unitNumber = json["unitNumber"].string
        
        self.city = json["city"].string
        self.country = json["country"].string
        
        self.postal = json["postal"].string
        self.lat = json["lat"].double
        self.lng = json["lng"].double
    }
    
}

struct Menu {
    var type: Int?
    
    var thumbUrl: String?
    var url: String?
    
    init(json: JSON) {
        self.type = json["type"].int
        
        self.thumbUrl = json["thumbUrl"].string
        self.url = json["url"].string
    }
    
    func thumbImageURL() -> URL? {
        if let imageUrl = self.thumbUrl {
            return URL(string: imageUrl)
        } else {
            return nil
        }
    }
}

class HourFormatter {
    static let instance = HourFormatter()
    static let days = [
        1 : "Mon",
        2 : "Tue",
        3 : "Wed",
        4 : "Thu",
        5 : "Fri",
        6 : "Sat",
        7 : "Sun",
        100 : "PH"
    ]
    
    let inFormatter = DateFormatter()
    let outFormatter = DateFormatter()
    
    init() {
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        inFormatter.dateFormat = "HH:mm"
        
        outFormatter.locale = Locale(identifier: "en_US_POSIX")
        outFormatter.dateFormat = "h:mm a"
    }
    
    func format(string: String) -> String {
        let date = inFormatter.date(from: string)
        return outFormatter.string(from: date!)
    }
    
    class func format(hour: Hour) -> String {
        let open = instance.format(string: hour.open!)
        let close = instance.format(string: hour.close!)
        return "\(open) - \(close)"
    }
}

struct Hour {
    var day: Int?
    var open: String?
    var close: String?
    
    init(json: JSON) {
        self.day = json["day"].int
        self.open = json["open"].string
        self.close = json["close"].string
    }
    
    func rangeText() -> String {
        return HourFormatter.format(hour: self)
    }
    
    func dayText() -> String {
        return HourFormatter.days[day!]!
    }
}

struct Graphic {
    var id: String?
    
    var mediaId: String?
    var imageUrl: String?
    
    init(json: JSON) {
        self.id = json["id"].string
        
        self.mediaId = json["mediaId"].string
        self.imageUrl = json["imageUrl"].string
    }
    
    func imageURL() -> URL? {
        if let imageUrl = self.imageUrl {
            return URL(string: imageUrl)
        } else {
            return nil
        }
    }
}

struct Article {
    var id: String?
    
    var author: String?
    var summary: String?
    var imageUrl: String?
    var url: String?
    
    init(json: JSON) {
        self.id = json["id"].string
        
        self.author = json["author"].string
        self.summary = json["summary"].string
        self.imageUrl = json["imageUrl"].string
        self.url = json["url"].string
    }
    
    func imageURL() -> URL? {
        if let imageUrl = self.imageUrl {
            return URL(string: imageUrl)
        } else {
            return nil
        }
    }
}

struct Image {
    var url: String?
    
    init(json: JSON) {
        self.url = json["url"].string
    }
}
