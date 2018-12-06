//
// Created by Fuxing Loh on 19/8/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

class CollectionPlaceLoader {
    private let disposeBag = DisposeBag()
    private let provider = MunchProvider<UserPlaceCollectionService>()
    private var observer: AnyObserver<([UserPlaceCollection.Item], Bool)>?

    private(set) var collection: UserPlaceCollection?
    private(set) var items: [UserPlaceCollection.Item] = []

    private(set) var next: Int?
    private(set) var more: Bool = false

    public var isEditable: Bool {
        return false
    }

    func start(collectionId: String) -> Single<UserPlaceCollection> {
        return provider.rx.request(.get(collectionId))
                .map { response throws -> UserPlaceCollection in
                    return try response.map(data: UserPlaceCollection.self)
                }.do(onSuccess: { collection in
                    self.collection = collection
                    self.more = true
                })
    }

    func observe() -> Observable<([UserPlaceCollection.Item], Bool)> {
        return Observable.create { (observer: AnyObserver<([UserPlaceCollection.Item], Bool)>) in
            self.observer = observer
            return Disposables.create()
        }
    }

    func append() {
        guard more, let collectionId = self.collection?.collectionId else {
            return
        }
        self.more = false

        provider.rx.request(.itemsList(collectionId, 15, next))
                .map { response throws -> (Int?, [UserPlaceCollection.Item]) in
                    let items = try response.map(data: [UserPlaceCollection.Item].self)
                    let next = try response.mapNext()
                    let sort = next?["sort"] as? Int
                    return (sort, items)
                }.subscribe { event in
                    switch event {
                    case let .success(sort, items):
                        self.items.append(contentsOf: items)
                        self.next = sort
                        self.more = sort != nil

                        self.observer?.on(.next((self.items, self.more)))
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }
}
