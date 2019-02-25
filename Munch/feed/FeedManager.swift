//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum FeedCellItem {
    case image(FeedItem, [Place])
}

extension FeedQuery {
    static func create() -> FeedQuery {
        let location = FeedQuery.Location(latLng: nil)
        return FeedQuery(location: location)
    }
}

class FeedManager {
    private let provider = MunchProvider<FeedQueryService>()

    fileprivate(set) var loading = false
    fileprivate(set) var items = [FeedItem]()
    fileprivate(set) var places = [String: Place?]()
    fileprivate(set) var eventDate = Date()

    private var query = FeedQuery.create()

    var more: Bool {
        return loading || from != nil
    }

    private var from: Int? = 0
    private var observer: AnyObserver<[FeedCellItem]>?
    private let disposeBag = DisposeBag()

    func reset(latLng: String? = nil) {
        self.query.location.latLng = latLng

        self.items.removeAll()
        self.places.removeAll()
        self.from = 0
        self.loading = false
        self.observer?.on(.next(self.collect()))
        self.append()
    }

    func observe() -> Observable<[FeedCellItem]> {
        return Observable.create { (observer: AnyObserver<[FeedCellItem]>) in
            self.observer = observer
            return Disposables.create()
        }
    }

    func append() {
        guard let from = self.from, from < 500 else {
            self.loading = false
            return
        }

        if loading {
            return
        }

        self.loading = true

        self.provider.rx.request(.query(self.query, from, 20))
                .map { res throws -> ([FeedItem], [String: Place?], Int?) in
                    let from = try res.mapNext(atKeyPath: "from") as? Int
                    let items = try res.map(data: [FeedItem].self)
                    let places = try res.map([String: Place?].self, atKeyPath: "places")
                    return (items, places, from)
                }
                .subscribe { event in
                    switch event {
                    case let .success(items, places, from):
                        self.loading = false
                        self.items.append(contentsOf: items)
                        places.forEach { key, value in
                            self.places[key] = value
                        }
                        self.observer?.on(.next(self.collect()))
                        self.from = from

                        MunchAnalytic.logEvent("feed_query", parameters: [
                            "count": (self.from ?? 0) as NSObject
                        ])
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    private func collect() -> [FeedCellItem] {
        var list = [FeedCellItem]()
        items.forEach { item in
            var places = [Place]()
            item.places.map({ $0.placeId }).forEach { s in
                if let place = self.places[s] as? Place {
                    places.append(place)
                }
            }

            list.append(FeedCellItem.image(item, places))
        }
        return list
    }
}