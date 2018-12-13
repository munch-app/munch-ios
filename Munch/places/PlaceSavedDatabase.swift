//
// Created by Fuxing Loh on 2018-12-13.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum SavedType {
    case put
    case delete
}

class PlaceSavedDatabase {
    private let provider = MunchProvider<UserSavedPlaceService>()
    private let disposeBag = DisposeBag()

    private var items = [UserSavedPlace]()
    private var observer: AnyObserver<[UserSavedPlace]>?

    func load(next: Int? = nil) {
        if next == nil {
            self.items.removeAll()
        }

        provider.rx.request(.list(next, 40))
                .map { response -> ([UserSavedPlace], Int?) in
                    let places = try response.map(data: [UserSavedPlace].self)
                    let next = try response.mapNext(atKeyPath: "createdMillis") as? Int
                    return (places, next)
                }
                .subscribe { (event: SingleEvent<([UserSavedPlace], Int?)>) in
                    switch event {
                    case let .success(items, next):
                        self.items.append(contentsOf: items)
                        self.observer?.on(.next(items))

                        if let next = next {
                            self.load(next: next)
                        }

                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
    }

    func observe() -> Observable<[UserSavedPlace]> {
        return Observable.create { (observer: AnyObserver<[UserSavedPlace]>) in
            self.observer = observer
            return Disposables.create()
        }
    }

    func isSaved(placeId: String) -> Bool {
        return self.items.contains { place in
            place.placeId == placeId
        }
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
                    self.load()
                })
    }

    func delete(placeId: String) -> Single<Bool> {
        return provider.rx.request(.delete(placeId))
                .map({ response -> Bool in false })
                .do(onSuccess: { b in
                    self.load()
                })
    }
}

extension PlaceSavedDatabase {
    static let shared = PlaceSavedDatabase()
}