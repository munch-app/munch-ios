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
    var images: [Image]?
    
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
        self.images = json["images"].map({Image(json: $0.1)})
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

struct Image {
    var url: String?
    
    init(json: JSON) {
        self.url = json["url"].string
    }
}
