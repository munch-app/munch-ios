//
// Created by Fuxing Loh on 2018-12-06.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum RIPImageItem {
    case image(PlaceImage)
}

class RIPImageLoader {
    private let provider = MunchProvider<PlaceService>()

    fileprivate(set) var loading = false
    fileprivate(set) var items = [RIPImageItem]()

    private var observer: AnyObserver<[RIPImageItem]>?
    private let disposeBag = DisposeBag()

    private var placeId: String!
    private var next: String?

    var more: Bool {
        return next != nil
    }

    func start(placeId: String, images: [PlaceImage]) {
        self.placeId = placeId
        self.next = images.last?.sort
        self.append(images: images)
    }

    func observe() -> Observable<[RIPImageItem]> {
        return Observable.create { (observer: AnyObserver<[RIPImageItem]>) in
            self.observer = observer
            return Disposables.create()
        }
    }

    func append() {
        guard let next = self.next, items.count < 500 else {
            return
        }

        if loading {
            return
        }

        self.loading = true

        self.provider.rx.request(.images(self.placeId, next))
                .map { res -> ([PlaceImage], String?) in
                    let images = try res.map(data: [PlaceImage].self)
                    let sort = try res.mapNext(atKeyPath: "sort") as? String
                    return (images, sort)
                }
                .subscribe { event in
                    switch event {
                    case let .success(images, next):
                        self.loading = false
                        self.next = next
                        self.append(images: images)
                        self.observer?.on(.next(self.items))

                        MunchAnalytic.logEvent("rip_image_query", parameters: [
                            "count" : self.items.count as NSObject
                        ])
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    private func append(images: [PlaceImage]) {
        images.forEach { image in
            items.append(.image(image))
        }
    }
}