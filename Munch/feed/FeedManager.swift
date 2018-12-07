//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum FeedCellItem {
    case image(ImageFeedItem, [Place])
}

class FeedManager {
    private let provider = MunchProvider<FeedImageService>()

    fileprivate(set) var loading = false
    fileprivate(set) var items = [ImageFeedItem]()
    fileprivate(set) var places = [String: Place?]()
    fileprivate(set) var eventDate = Date()

    private var from: Int? = 0
    private var observer: AnyObserver<[FeedCellItem]>?
    private let disposeBag = DisposeBag()

    func reset() {
        self.items.removeAll()
        self.places.removeAll()
        self.from = 0
        self.loading = false
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
            return
        }

        if loading {
            return
        }

        self.loading = true

        self.provider.rx.request(.query("sgp", latLng, from))
                .map { res -> (ImageFeedResult, Int?) in
                    let from = try res.mapNext(atKeyPath: "from") as? Int
                    let result = try res.map(data: ImageFeedResult.self)
                    return (result, from)
                }
                .subscribe { event in
                    switch event {
                    case let .success(result, from):
                        self.loading = false
                        self.items.append(contentsOf: result.items)
                        result.places.forEach { key, value in
                            self.places[key] = value
                        }
                        self.observer?.on(.next(self.collect()))
                        self.from = from

                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    private var latLng: String {
        return MunchLocation.lastLatLng ?? "1.3521,103.8198"
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