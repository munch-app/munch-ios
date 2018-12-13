//
// Created by Fuxing Loh on 2018-12-13.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

import RealmSwift

enum SavedType {
    case put
    case delete
}

class PlaceSavedData: Object {
    @objc dynamic var placeId: String = ""
    @objc dynamic var userId: String = ""
    @objc dynamic var name: String = ""

    @objc dynamic var createdMillis: Int = 0
    @objc dynamic var place: Data?

    override class func primaryKey() -> String? {
        return "placeId"
    }

    static func from(place: UserSavedPlace) -> PlaceSavedData {
        let data = PlaceSavedData()
        data.userId = place.userId
        data.placeId = place.placeId
        data.name = place.name
        data.createdMillis = place.createdMillis
        data.place = place.place != nil ? try? JSONEncoder().encode(place.place) : nil
        return data
    }

    func to() -> UserSavedPlace {
        return UserSavedPlace(userId: self.userId,
                placeId: self.placeId,
                name: self.name,
                createdMillis: self.createdMillis,
                place: self.place != nil ? try? JSONDecoder().decode(Place.self, from: self.place!) : nil)
    }
}

class PlaceSavedDatabase {
    private let provider = MunchProvider<UserSavedPlaceService>()
    private let disposeBag = DisposeBag()

    private var placeIds = Set<String>()
    private var observers = [AnyObserver<[UserSavedPlace]>]()

    init() {
        let realm = try! Realm()
        realm.objects(PlaceSavedData.self).forEach { object in
            placeIds.insert(object.placeId)
        }
    }

    func observe() -> Observable<[UserSavedPlace]> {
        return Observable.create { (observer: AnyObserver<[UserSavedPlace]>) in
            self.observers.append(observer)
            return Disposables.create()
        }
    }

    func reload() {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(realm.objects(PlaceSavedData.self))
        }

        self.placeIds.removeAll()
        self.load(next: nil)
    }

    private func load(next: Int? = nil) {
        provider.rx.request(.list(next, 40))
                .map { response -> ([UserSavedPlace], Int?) in
                    let places = try response.map(data: [UserSavedPlace].self)
                    let next = try response.mapNext(atKeyPath: "createdMillis") as? Int
                    return (places, next)
                }
                .subscribe { (event: SingleEvent<([UserSavedPlace], Int?)>) in
                    switch event {
                    case let .success(items, next):
                        let realm = try! Realm()

                        try! realm.write {
                            items.forEach { place in
                                self.placeIds.insert(place.placeId)
                                realm.create(PlaceSavedData.self, value: PlaceSavedData.from(place: place), update: true)
                            }
                        }

                        var items = [UserSavedPlace]()
                        realm.objects(PlaceSavedData.self)
                                .sorted(byKeyPath: "createdMillis", ascending: false)
                                .forEach { data in
                                    items.append(data.to())
                                }


                        self.observers.forEach { observer in
                            observer.on(.next(items))
                        }

                        if let next = next {
                            self.load(next: next)
                        }
                    default:
                        return
                    }
                }.addDisposableTo(disposeBag)
    }

    func isSaved(placeId: String) -> Bool {
        return placeIds.contains(placeId)
    }

    func toggle(placeId: String) -> Single<Bool> {
        if isSaved(placeId: placeId) {
            return delete(placeId: placeId)
        } else {
            return put(placeId: placeId)
        }
    }

    func put(placeId: String) -> Single<Bool> {
        return provider.rx.request(.put(placeId))
                .map({ response -> Bool in true })
                .do(onSuccess: { b in
                    self.reload()
                })
    }

    func delete(placeId: String) -> Single<Bool> {
        return provider.rx.request(.delete(placeId))
                .map({ response -> Bool in false })
                .do(onSuccess: { b in
                    self.reload()
                })
    }
}

extension PlaceSavedDatabase {
    static let shared = PlaceSavedDatabase()
}