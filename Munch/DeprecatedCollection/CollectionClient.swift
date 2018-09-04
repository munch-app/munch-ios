//
// Created by Fuxing Loh on 16/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class CollectionClient {
    // Temporary solution to track collection changed date
    var changedDate = Date()

    let liked = LikedClient()
    let recent = RecentClient()

    /**
     Create new PlaceCollection
     */
    func post(collection: PlaceCollection, callback: @escaping (_ meta: MetaJSON, _ collection: PlaceCollection?) -> Void) {
        self.changedDate = Date()
        MunchApi.restful.post("/collections", parameters: collection.toParams()) { meta, json in
            callback(meta, PlaceCollection(json: json["data"]))
        }
    }

    /**
     Update existing PlaceCollection
     */
    func put(collectionId: String, collection: PlaceCollection, callback: @escaping (_ meta: MetaJSON, _ collection: PlaceCollection?) -> Void) {
        self.changedDate = Date()
        MunchApi.restful.put("/collections/\(collectionId)", parameters: collection.toParams()) { meta, json in
            callback(meta, PlaceCollection(json: json["data"]))
        }
    }

    func list(maxSortKey: Int?, size: Int, callback: @escaping (_ meta: MetaJSON, _ collections: [PlaceCollection]) -> Void) {
        var params = Parameters()
        params["maxSortKey"] = maxSortKey
        params["size"] = size

        MunchApi.restful.get("/collections", parameters: params) { meta, json in
            callback(meta, json["data"].compactMap({ PlaceCollection(json: $0.1) }))
        }
    }

    /**
     if userId is given, user is accessing the public collection endpoint
     */
    func get(userId: String? = nil, collectionId: String, callback: @escaping (_ meta: MetaJSON, _ collection: PlaceCollection?) -> Void) {
        if let userId = userId {
            MunchApi.restful.get("/public/collections/\(userId)/\(collectionId)") { meta, json in
                callback(meta, PlaceCollection(json: json["data"]))
            }
        } else {
            MunchApi.restful.get("/collections/\(collectionId)") { meta, json in
                callback(meta, PlaceCollection(json: json["data"]))
            }
        }
    }

    func delete(collectionId: String, callback: @escaping (_ meta: MetaJSON) -> Void) {
        self.changedDate = Date()
        MunchApi.restful.delete("/collections/\(collectionId)") { meta, json in
            callback(meta)
        }
    }

    func putPlace(collectionId: String, placeId: String, callback: @escaping (_ meta: MetaJSON) -> Void) {
        self.changedDate = Date()
        MunchApi.restful.put("/collections/\(collectionId)/places/\(placeId)") { meta, json in
            callback(meta)
        }
    }

    func deletePlace(collectionId: String, placeId: String, callback: @escaping (_ meta: MetaJSON) -> Void) {
        self.changedDate = Date()
        MunchApi.restful.delete("/collections/\(collectionId)/places/\(placeId)") { meta, json in
            callback(meta)
        }
    }

    /**
     if userId is given, user is accessing the public collection endpoint
     */
    func listPlace(userId: String? = nil, collectionId: String, maxSortKey: Int?, size: Int, callback: @escaping (_ meta: MetaJSON, _ addedPlaces: [PlaceCollection.AddedPlace]) -> Void) {
        var params = Parameters()
        params["maxSortKey"] = maxSortKey
        params["size"] = size

        if let userId = userId {
            MunchApi.restful.get("/public/collections/\(userId)/\(collectionId)/places", parameters: params) { meta, json in
                callback(meta, json["data"].map({ PlaceCollection.AddedPlace(json: $0.1) }))
            }
        } else {
            MunchApi.restful.get("/collections/\(collectionId)/places", parameters: params) { meta, json in
                callback(meta, json["data"].map({ PlaceCollection.AddedPlace(json: $0.1) }))
            }
        }
    }

    class LikedClient {
        func list(maxSortKey: Int?, size: Int, callback: @escaping (_ meta: MetaJSON, _ places: [LikedPlace]) -> Void) {
            var params = Parameters()
            params["maxSortKey"] = maxSortKey
            params["size"] = size

            MunchApi.restful.get("/collections/likes", parameters: params) { meta, json in
                callback(meta, json["data"].map({ LikedPlace(json: $0.1) }))
            }
        }

        func put(placeId: String, callback: @escaping (_ meta: MetaJSON) -> Void) {
            MunchApi.collections.changedDate = Date()
            MunchApi.restful.put("/collections/likes/\(placeId)") { meta, json in
                callback(meta)
            }
        }

        func delete(placeId: String, callback: @escaping (_ meta: MetaJSON) -> Void) {
            MunchApi.collections.changedDate = Date()
            MunchApi.restful.delete("/collections/likes/\(placeId)") { meta, json in
                callback(meta)
            }
        }
    }

    class RecentClient {
        func put(placeId: String, callback: @escaping (_ meta: MetaJSON) -> Void) {
            MunchApi.restful.put("/collections/recents/\(placeId)") { meta, json in
                callback(meta)
            }
        }
    }
}


struct LikedPlace {
    var place: DeprecatedPlace
    var sortKey: Int
    var createdDate: Date

    init(json: JSON) {
        self.place = DeprecatedPlace(json: json["place"])!
        self.sortKey = json["sortKey"].intValue
        self.createdDate = Date(timeIntervalSince1970: (json["createdDate"].doubleValue / 1000.0))
    }
}

struct PlaceCollection {
    var userId: String?
    var collectionId: String?

    var sortKey: Int?

    var privacy: String?

    var name: String?
    var description: String?
    var count: Int?

    var thumbnail: [String: String]?

    var updatedDate: Date?
    var createdDate: Date?

    init() {

    }

    init?(json: JSON) {
        guard json.exists() else {
            return nil
        }
        self.userId = json["userId"].string
        self.collectionId = json["collectionId"].string

        self.sortKey = json["sortKey"].int
        self.privacy = json["privacy"].string

        self.name = json["name"].string
        self.description = json["description"].string
        self.count = json["count"].int

        self.thumbnail = json["thumbnail"].dictionaryObject as? [String: String]

        if let updatedDate = json["updatedDate"].double {
            self.updatedDate = Date(timeIntervalSince1970: (updatedDate / 1000.0))
        }

        if let createdDate = json["createdDate"].double {
            self.createdDate = Date(timeIntervalSince1970: (createdDate / 1000.0))
        }
    }

    /**
     Only params that service needs
     */
    func toParams() -> Parameters {
        var parameters = Parameters()
        parameters["sortKey"] = sortKey
        parameters["privacy"] = privacy

        parameters["name"] = name
        parameters["description"] = description
        return parameters
    }

    struct AddedPlace {
        var place: Place
        var sortKey: Int
        var createdDate: Date

        init(json: JSON) {
            self.place = DeprecatedPlace(json: json["place"])!
            self.sortKey = json["sortKey"].intValue
            self.createdDate = Date(timeIntervalSince1970: (json["createdDate"].doubleValue / 1000.0))
        }
    }
}