//
// Created by Fuxing Loh on 17/8/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RealmSwift
import RxSwift

class UserPlaceCollectionObject: Object {
    @objc dynamic var collectionId: String = ""
    @objc dynamic var sort: Int = 0
    @objc dynamic var updatedMillis: Int = 0

    @objc dynamic var data: Data?
}

class UserPlaceCollectionDatabase {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let disposeBag = DisposeBag()
    private let provider = MunchProvider<UserPlaceCollectionService>()
    private var observer: AnyObserver<[UserPlaceCollection]>?

    // Subscribe to Data
    // -> Data Stored in Local Realm will be returned first
    // -> Server call will happen and check for changes, if changes, return
    // -> User Create or Update, will return also
    func observe() -> Observable<[UserPlaceCollection]> {
        return Observable.create { (observer: AnyObserver<[UserPlaceCollection]>) in
            self.observer = observer

            self.sendLocal()
            self.refresh()
            return Disposables.create()
        }
    }

    func sendLocal() {
        let realm = try! Realm()
        let objects = realm.objects(UserPlaceCollectionObject.self)
                .sorted(byKeyPath: "sort", ascending: false)

        let collections = Array(objects).map { (object: UserPlaceCollectionObject) -> UserPlaceCollection in
            return try! self.decoder.decode(UserPlaceCollection.self, from: object.data!)
        }
        if collections.isEmpty {
            // If it's empty, wait for server reply
            return
        }

        self.observer?.on(.next(collections))
    }

    func get(collectionId: String, withCompletion: @escaping (SingleEvent<UserPlaceCollection>) -> ()) {
        provider.rx.request(.get(collectionId))
                .map { response -> UserPlaceCollection in
                    return try response.map(data: UserPlaceCollection.self)
                }.subscribe { event in
                    switch event {
                    case let .success(collection):
                        let realm = try! Realm()
                        try! realm.write {
                            let objects = realm.objects(UserPlaceCollectionObject.self).filter("collectionId == '\(collectionId)'")
                            realm.delete(objects)

                            let object = UserPlaceCollectionObject()
                            object.collectionId = collection.collectionId!
                            object.sort = collection.sort!
                            object.updatedMillis = collection.updatedMillis!
                            object.data = try! self.encoder.encode(collection)
                            realm.add(object)
                        }
                        self.sendLocal()
                        withCompletion(.success(collection))

                    case let .error(error):
                        self.observer?.on(.error(error))
                        withCompletion(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    private func refresh() {
        var collected: [UserPlaceCollection] = []

        func query(next: Int?) {
            provider.rx.request(.list(10, next))
                    .map { response throws -> (Int?, [UserPlaceCollection]) in
                        let items = try response.map(data: [UserPlaceCollection].self)
                        let next = try response.mapNext()
                        let sort = next?["sort"] as? Int
                        return (sort, items)
                    }
                    .subscribe { event in
                        switch event {
                        case let .success(sort, items):
                            collected.append(contentsOf: items)
                            if let sort = sort {
                                query(next: sort)
                            } else {
                                self.replace(collections: collected)
                            }
                        case .error(let error):
                            self.observer?.on(.error(error))
                        }
                    }
                    .disposed(by: disposeBag)
        }

        query(next: nil)
    }

    private func replace(collections: [UserPlaceCollection]) {
        let realm = try! Realm()
        let objects = realm.objects(UserPlaceCollectionObject.self)

        let totalService: Int = collections.reduce(into: 0) { (v: inout Int, collection: UserPlaceCollection) in
            v = v + collection.updatedMillis!
        }
        let totalDatabase: Int = objects.reduce(into: 0) { (v: inout Int, object: UserPlaceCollectionObject) in
            v = v + object.updatedMillis
        }

        if totalService == totalDatabase {
            return
        }

        try! realm.write {
            realm.delete(objects)
            for collection in collections {
                let object = UserPlaceCollectionObject()
                object.collectionId = collection.collectionId!
                object.sort = collection.sort!
                object.updatedMillis = collection.updatedMillis!
                object.data = try! encoder.encode(collection)
                realm.add(object)
            }
        }

        observer?.on(.next(collections))
    }

    func create(collection: UserPlaceCollection) {
        provider.rx.request(.post(collection))
                .map { response throws -> UserPlaceCollection in
                    return try response.map(data: UserPlaceCollection.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let collection):
                        let realm = try! Realm()
                        try! realm.write {
                            let object = UserPlaceCollectionObject()
                            object.collectionId = collection.collectionId!
                            object.sort = collection.sort!
                            object.updatedMillis = collection.updatedMillis!
                            object.data = try! self.encoder.encode(collection)
                            realm.add(object)
                        }
                        self.sendLocal()
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    func update(collection: UserPlaceCollection) {
        provider.rx.request(.patch(collection.collectionId!, collection))
                .map { response throws -> UserPlaceCollection in
                    return try response.map(data: UserPlaceCollection.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let collection):
                        let realm = try! Realm()
                        try! realm.write {
                            if let object = realm.objects(UserPlaceCollectionObject.self)
                                    .filter("collectionId == '\(collection.collectionId!)'").first {
                                object.collectionId = collection.collectionId!
                                object.sort = collection.sort!
                                object.updatedMillis = collection.updatedMillis!
                                object.data = try! self.encoder.encode(collection)
                            }
                        }
                        self.sendLocal()
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    func has(collection: UserPlaceCollection, place: Place) -> Bool {
        let realm = try! Realm()
        if let collectionId = collection.collectionId {
            if realm.objects(UserPlaceCollectionItemObject.self)
                       .filter("collectionId == '\(collectionId)' AND placeId == '\(place.placeId)'").first != nil {
                return true
            }
        }
        return false
    }
}

class UserPlaceCollectionItemObject: Object {
    @objc dynamic var collectionId: String = ""
    @objc dynamic var placeId: String = ""

    @objc dynamic var sort: Int = 0
    @objc dynamic var createdMillis: Int = 0
    @objc dynamic var place: Data?
}

class UserPlaceCollectionItemDatabase {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let disposeBag = DisposeBag()
    private let provider = MunchProvider<UserPlaceCollectionService>()
    private var observer: AnyObserver<[UserPlaceCollection.Item]>?

    func observe(collection: UserPlaceCollection) -> Observable<[UserPlaceCollection.Item]> {
        return Observable.create { (observer: AnyObserver<[UserPlaceCollection.Item]>) in
            self.observer = observer
            self.sendLocal(collection: collection)
            self.refresh(collection: collection)
            return Disposables.create()
        }
    }

    func get(collection: UserPlaceCollection) -> [UserPlaceCollection.Item] {
        let realm = try! Realm()
        let objects = realm.objects(UserPlaceCollectionItemObject.self)
                .filter("collectionId == '\(collection.collectionId!)'")
                .sorted(byKeyPath: "sort", ascending: true)

        return Array(objects).map { (object: UserPlaceCollectionItemObject) -> UserPlaceCollection.Item in
            return UserPlaceCollection.Item(collectionId: object.collectionId,
                    placeId: object.placeId,
                    sort: object.sort,
                    createdMillis: object.createdMillis,
                    place: try? decoder.decode(Place.self, from: object.place!))
        }
    }

    private func sendLocal(collection: UserPlaceCollection) {
        let items = get(collection: collection)

        // If it's empty, wait for server reply
        if items.isEmpty {
            return
        }

        self.observer?.on(.next(items))
    }

    private func refresh(collection: UserPlaceCollection) {
        var collected: [UserPlaceCollection.Item] = []

        func query(next: Int?) {
            provider.rx.request(.itemsList(collection.collectionId!, 50, next))
                    .map { response throws -> (Int?, [UserPlaceCollection.Item]) in
                        let items = try response.map(data: [UserPlaceCollection.Item].self)
                        let next = try response.mapNext()
                        let sort = next?["sort"] as? Int
                        return (sort, items)
                    }
                    .subscribe { event in
                        switch event {
                        case let .success(sort, items):
                            collected.append(contentsOf: items)
                            if let sort = sort {
                                query(next: sort)
                            } else {
                                self.replace(collection: collection, items: collected)
                            }
                        case .error(let error):
                            self.observer?.on(.error(error))
                        }
                    }
                    .disposed(by: disposeBag)
        }

        query(next: nil)
    }

    private func replace(collection: UserPlaceCollection, items: [UserPlaceCollection.Item]) {
        let realm = try! Realm()
        let objects = realm.objects(UserPlaceCollectionItemObject.self)
                .filter("collectionId == '\(collection.collectionId!)'")

        let totalService: Int = items.reduce(into: 0) { (v: inout Int, item: UserPlaceCollection.Item) in
            v = v + item.createdMillis
        }
        let totalDatabase: Int = objects.reduce(into: 0) { (v: inout Int, object: UserPlaceCollectionItemObject) in
            v = v + object.createdMillis
        }

        if totalService == totalDatabase {
            return
        }

        try! realm.write {
            realm.delete(objects)
            for item in items {
                let object = UserPlaceCollectionItemObject()
                object.createdMillis = item.createdMillis
                object.sort = item.sort
                object.collectionId = item.collectionId
                object.placeId = item.placeId
                object.place = try? self.encoder.encode(item.place)
                realm.add(object)
            }
        }

        observer?.on(.next(items))
    }

    func add(collection: UserPlaceCollection, place: Place, onComplete: @escaping((Error?) -> Void)) {
        provider.rx.request(.itemsPut(collection.collectionId!, place.placeId))
                .map { response throws -> UserPlaceCollection.Item in
                    return try response.map(data: UserPlaceCollection.Item.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let item):
                        let realm = try! Realm()
                        try! realm.write {
                            let object = UserPlaceCollectionItemObject()
                            object.collectionId = item.collectionId
                            object.sort = item.sort
                            object.placeId = item.placeId
                            object.createdMillis = item.createdMillis
                            object.place = try? self.encoder.encode(place)
                            realm.add(object)
                        }
                        onComplete(nil)
                        self.sendLocal(collection: collection)

                    case .error(let error):
                        if error.type == "munch.api.user.ItemAlreadyExistInPlaceCollection" {
                            self.get(collection: collection, place: place, onComplete: onComplete)
                            return
                        }

                        onComplete(error)
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    func get(collection: UserPlaceCollection, place: Place, onComplete: @escaping((Error?) -> Void)) {
        self.provider.rx.request(.itemsGet(collection.collectionId!, place.placeId))
                .map { response throws -> UserPlaceCollection.Item in
                    return try response.map(data: UserPlaceCollection.Item.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let item):
                        let realm = try! Realm()
                        try! realm.write {
                            let object = UserPlaceCollectionItemObject()
                            object.collectionId = item.collectionId
                            object.sort = item.sort
                            object.placeId = item.placeId
                            object.createdMillis = item.createdMillis
                            object.place = try? self.encoder.encode(place)
                            realm.add(object)
                        }
                        onComplete(nil)
                        self.sendLocal(collection: collection)

                    case .error(let error):
                        onComplete(error)
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)

    }

    func remove(collection: UserPlaceCollection, placeId: String, onComplete: @escaping((Error?) -> Void)) {
        provider.rx.request(.itemsDelete(collection.collectionId!, placeId))
                .map { response throws -> UserPlaceCollection.Item in
                    return try response.map(data: UserPlaceCollection.Item.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let item):
                        let realm = try! Realm()
                        try! realm.write {
                            let objects = realm.objects(UserPlaceCollectionItemObject.self)
                                    .filter("collectionId == '\(item.collectionId)' AND placeId == '\(item.placeId)'")
                            realm.delete(objects)
                        }
                        onComplete(nil)
                        self.sendLocal(collection: collection)

                    case .error(let error):
                        onComplete(error)
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }
}