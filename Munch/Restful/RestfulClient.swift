//
//  RestfulClient.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON

public class RestfulClient {
    
    private let url: String
    
    init(_ url: String) {
        self.url = url
        
    }
    
    func get(_ path: String, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        Alamofire.request(url + path, method: .get).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                callback(MetaJSON(metaJson: json["meta"]), json)
            case .failure(let error):
                print(error)
                // TODO handle timeout
            }
        }
    }
    
    func post(_ path: String, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        post(path, [:], callback: callback)
    }
    
    func post(_ path: String,_ parameters: Parameters, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        Alamofire.request(url + path, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    callback(MetaJSON(metaJson: json["meta"]), json)
                case .failure(let error):
                    print(error)
                }
        }
    }
    
}

/**
 Meta Json in response
 {meta: {}}
 */
public struct MetaJSON {
    public let code: Int!
    public let errorType: String?
    public let errorMessage: String?
    
    public init(metaJson: JSON){
        self.code = metaJson["code"].intValue
        self.errorType = metaJson["errorType"].string
        self.errorMessage = metaJson["errorMessage"].string
    }
    
    /**
     Returns true if meta is successful
     */
    public func isOk() -> Bool {
        return code == 200
    }
    
    /**
     Create an UI Alert Controller with prefilled info to
     easily print error message as alert dialog
     */
    public func createAlert() -> UIAlertController {
        let type = errorType ?? "Unknown Error"
        let message = errorMessage ?? "An unknown error has occured."
        let alert = UIAlertController(title: type, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}

class MunchClient: RestfulClient {
    static let baseUrl = "http://192.168.1.197:8088/v1"
    
    let places = PlaceClient(baseUrl)
    
    init() {
        super.init(MunchClient.baseUrl)
    }
    
    func discover(spatial: Spatial, callback: @escaping (_ meta: MetaJSON, _ places: [Place]) -> Void) {
        super.post("/discover", ["spatial": spatial.parameters()]) { meta, json in
            var places = [Place]()
            for(_, subJson) in json["data"] {
                places.append(Place(json: subJson))
            }
            callback(meta, places)
        }
    }
    
}


class PlaceClient: RestfulClient {
    
    func get(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place) -> Void) {
        super.get("/places/\(id)") { meta, json in
            callback(meta, Place(json: json["data"]))
        }
    }
    
}
