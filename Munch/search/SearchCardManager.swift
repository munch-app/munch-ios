//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift

import Firebase
import Crashlytics

class SearchCardManager {
    private let provider = MunchProvider<SearchService>()
    private let disposeBag = DisposeBag()
    private var observer: AnyObserver<[SearchCard]>?

    var searchQuery: SearchQuery
    var page: Int = 0

    let startDate = Date()

    fileprivate(set) var cards: [SearchCard] = []
    // Whether this card manager is currently loading more content
    fileprivate(set) var loading = false
    // Whether this card manager still contains more content to be loaded
    fileprivate(set) var more = true

    fileprivate(set) var started = false

    fileprivate(set) var qid: String?

    init(query: SearchQuery) {
        self.searchQuery = query
    }

    public func start() -> Observable<[SearchCard]> {
        return Observable.create { (observer: AnyObserver<[SearchCard]>) in
            self.observer = observer
            self.observer?.on(.next([
                SearchShimmerPlaceCard.card,
                SearchShimmerPlaceCard.card,
                SearchShimmerPlaceCard.card,
            ]))

            // Check if Location is Enabled, Inject Location
            return MunchLocation.request()
                    .subscribe { event in
                        switch event {
                        case .success:
                            self.search().disposed(by: self.disposeBag)

                        case .error:
                            self.cards = [SearchStaticErrorCard.create(type: .location)]
                        }
                    }
        }
    }

    public func append() {
        self.search().disposed(by: disposeBag)
    }

    private func search() -> Disposable {
        if self.loading || !self.more {
            return Disposables.create()
        }

        self.loading = true
        return provider.rx.request(.search(searchQuery, page))
                .map { res throws -> [SearchCard] in
                    if let error = res.meta.error, let type = error.type {
                        if type == "UnsupportedException" {
                            return [SearchStaticUnsupportedCard.card]
                        } else {
                            return [SearchStaticErrorCard.create(type: .message(type, error.message))]
                        }
                    }

                    if self.page == 0 {
                        self.qid = try res.mapString(atKeyPath: "qid")
                    }

                    if let cards = try res.mapJSON(atKeyPath: "data") as? [[String: Any]] {
                        return cards.map({ SearchCard(dictionary: $0) })
                    }
                    return []
                }
                .subscribe({ result in
                    switch result {
                    case .success(let cards):
                        self.started = true

                        self.append(contents: cards)
                        self.more = !cards.isEmpty
                        self.page += 1

                    case .error(let error):
                        if let error = error as? MoyaError {
                            switch error {
                            case let .statusCode(response):
                                let type = response.meta.error?.type ?? "Unknown Error"
                                let message = response.meta.error?.message
                                self.cards.append(SearchStaticErrorCard.create(type: .message(type, message)))

                            case let .underlying(error, _):
                                self.cards.append(SearchStaticErrorCard.create(type: .error(error)))

                            default: break
                            }
                        }
                        self.more = false
                    }

                    self.loading = false
                    self.observer?.on(.next(self.cards))

                    if (!self.more) {
                        self.observer?.on(.completed)
                    }
                })
    }

    private func append(contents cards: [SearchCard]) {
        let filtered = cards.filter {
            !self.cards.contains($0)
        }
        self.cards.append(contentsOf: filtered)
    }
}