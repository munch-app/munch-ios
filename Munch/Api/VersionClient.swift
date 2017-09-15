//
//  VersionClient.swift
//  Munch
//
//  Created by Fuxing Loh on 15/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/**
 PlaceClient from PlaceService in munch-core/munch-api
 */
class VersionClient {
    func validate(callback: @escaping (_ meta: MetaJSON) -> Void) {
        MunchApi.restful.get("/versions/validate") { meta, json in
            callback(meta)
        }
    }
}
