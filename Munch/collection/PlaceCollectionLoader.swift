//
// Created by Fuxing Loh on 19/8/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RealmSwift
import RxSwift

class PlaceCollectionLoader {
    private let disposeBag = DisposeBag()
    private let provider = MunchProvider<UserPlaceCollectionService>()
    private var observer: AnyObserver<([UserPlaceCollection.Item], Bool)>?

    private(set) var collection: UserPlaceCollection?
    private(set) var items: [UserPlaceCollection.Item] = []
    private(set) var next: Int?
    private(set) var more: Bool = false

    func observe(collectionId: String, withCompletion: @escaping (UserPlaceCollection?, Error?) -> Void) -> Observable<([UserPlaceCollection.Item], Bool)> {
        provider.rx.request(.get(collectionId))
                .map { response throws -> UserPlaceCollection in
                    return try response.map(data: UserPlaceCollection.self)
                }
                .subscribe { event in
                    switch event {
                    case let .success(collection):
                        self.collection = collection
                        withCompletion(collection, nil)

                        self.more = true
                        self.loadMore()
                    case .error(let error):
                        withCompletion(nil, error)
                    }
                }
                .disposed(by: disposeBag)

        return Observable.create { (observer: AnyObserver<([UserPlaceCollection.Item], Bool)>) in
            self.observer = observer
            return Disposables.create()
        }
    }

    func loadMore() {
        guard more else {
            return
        }

        provider.rx.request(.itemsList(collection!.collectionId!, 15, next))
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
