//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation

import RealmSwift
import SwiftyJSON

class RecentHistory: Object {
    @objc dynamic var _name: String = ""
    @objc dynamic var _date = Int(Date().timeIntervalSince1970)

    @objc dynamic var text: String = ""
    @objc dynamic var json: Data?
}

class RecentData: Object {
    @objc dynamic var _name: String = ""
    @objc dynamic var _date = Int(Date().timeIntervalSince1970)


    @objc dynamic var id: String = ""
    @objc dynamic var data: Data?
}

class RecentDataDatabase<T> where T: Codable {
    private let type: T.Type
    private let name: String
    private let maxSize: Int

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    /*
     * type: Type for Codable
     * name: name of database
     * maxSize: max size of number of data to store in database
     */
    init(type: T.Type, name: String, maxSize: Int) {
        self.type = type
        self.name = name
        self.maxSize = maxSize
    }

    func add(id: String, data: T) {
        let encoded = try? encoder.encode(data)

        let realm = try! Realm()
        if let exist = realm.objects(RecentData.self)
                .filter("_name == '\(name)' AND id == '\(id)'").first {
            try! realm.write {
                exist._date = Int(Date().timeIntervalSince1970)
                exist.data = encoded
            }
        } else {
            try! realm.write {
                let recent = RecentData()
                recent._name = name
                recent.id = id
                recent.data = encoded

                realm.add(recent)
                self.deleteLimit(realm: realm)
            }
        }
    }

    func list() -> [T] {
        let realm = try! Realm()
        let dataList = realm.objects(RecentData.self)
                .filter("_name == '\(name)'")
                .sorted(byKeyPath: "_date", ascending: false)

        var list = [T]()
        for recent in dataList {
            if let data = recent.data, let decoded = try? decoder.decode(type, from: data) {
                list.append(decoded)
            }

            // If hit max items, auto return
            if (list.count >= maxSize) {
                return list
            }
        }
        return list
    }

    private func deleteLimit(realm: Realm = try! Realm()) {
        let saved = realm.objects(RecentHistory.self)
                .filter("_name == '\(name)'")
                .sorted(byKeyPath: "_date", ascending: false)

        // Delete if more then maxItems
        if (saved.count > maxSize) {
            for (index, element) in saved.enumerated() {
                if (index > maxSize) {
                    realm.delete(element)
                }
            }
        }
    }
}

// TODO Remove After Deprecated
class RecentJSONDatabase {
    private let name: String
    private let maxItems: Int

    init(name: String, maxItems: Int) {
        self.name = name
        self.maxItems = maxItems
    }

    func get() -> [(String, JSON?)] {
        let realm = try! Realm()
        let saved = realm.objects(RecentHistory.self)
                .filter("_name == '\(name)'")
                .sorted(byKeyPath: "_date", ascending: false)

        var list = [(String, JSON?)]()
        for history in saved {
            if let data = history.json {
                list.append((history.text, try? JSON(data: data)))
            } else {
                list.append((history.text, nil))
            }

            // If hit max items, auto return
            if (list.count >= maxItems) {
                return list
            }
        }
        return list
    }

    func put(text: String, dictionary: [String: Any]? = nil) {
        if let json = dictionary {
            put(text: text, json: JSON(json))
        } else {
            put(text: text, json: nil)
        }
    }

    func put(text: String, json: JSON?) {
        let realm = try! Realm()
        if let exist = realm.objects(RecentHistory.self)
                .filter("_name == '\(name)' AND text == '\(text)'").first {
            try! realm.write {
                exist._date = Int(Date().timeIntervalSince1970)
                exist.json = try json?.rawData()
            }
        } else {
            try! realm.write {
                let history = RecentHistory()
                history._name = name
                history.text = text
                history.json = try json?.rawData()
                realm.add(history)

                self.deleteLimit(realm: realm)
            }
        }
    }

    /**
     Transaction must already be open
     */
    private func deleteLimit(realm: Realm = try! Realm()) {
        let saved = realm.objects(RecentHistory.self)
                .filter("_name == '\(name)'")
                .sorted(byKeyPath: "_date", ascending: false)

        // Delete if more then maxItems
        if (saved.count > maxItems) {
            for (index, element) in saved.enumerated() {
                if (index > maxItems) {
                    realm.delete(element)
                }
            }
        }
    }
}