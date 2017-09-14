//
//  ResourcesClient.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON

/**
 CachedSyncClient from CachedSyncService in munch-core/munch-api
 */
class CachedSyncClient: RestfulClient {
    
    func hashes(callback: @escaping (_ meta: MetaJSON, _ hashes: [String: String]) -> Void) {
        super.get("/cached/hashes") { meta, json in
            var hashes = [String: String]()
            for hash in json["data"] {
                hashes[hash.0] = hash.1.stringValue
            }
            callback(meta, hashes)
        }
    }
    
    func get(type: String, callback: @escaping (_ meta: MetaJSON, _ hash: String?, _ json: JSON) -> Void) {
        super.get("/cached/data/\(type)") { meta, json in
            let hash = json["data"]["hash"].string
            let data = json["data"]["data"]
            callback(meta, hash, data)
        }
    }
}
