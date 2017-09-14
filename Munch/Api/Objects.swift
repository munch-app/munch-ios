//
//  Place.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON

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


