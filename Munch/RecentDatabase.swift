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

class RecentDatabase {
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