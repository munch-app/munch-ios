//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift

enum FeedCellItem {
    case image(ImageFeedItem)
}

class FeedManager {
    private let provider = MunchProvider<FeedImageService>()

    fileprivate(set) var loading = false
    fileprivate(set) var items = [ImageFeedItem]()

    private var from: Int? = 0
    private var observer: AnyObserver<[FeedCellItem]>?
    private let disposeBag = DisposeBag()

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
            list.append(.image(item))
        }
        return list
    }
}