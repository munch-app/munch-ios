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

    var searchQuery: SearchQuery
    var searchScreen: SearchScreen
    var page: Int = 0

    let startDate = Date()

    fileprivate(set) var cards: [SearchCard] = []
    // Whether this card manager is currently loading more content
    fileprivate(set) var loading = false
    // Whether this card manager still contains more content to be loaded
    fileprivate(set) var more = true

    init(query: SearchQuery, screen: SearchScreen) {
        self.searchQuery = query
        self.searchScreen = screen
    }

    public func start(_ observer: @escaping () -> ()) {
        // Check if Location is Enabled, Inject Location
        MunchLocation.request()
                .subscribe { event in
                    switch event {
                    case .success:
                        self.search(observer)
                                .disposed(by: self.disposeBag)

                    case .error:
                        self.cards = [SearchStaticErrorCard.create(type: .location)]
                        observer()
                    }
                }
                .disposed(by: disposeBag)
    }

    public func append(_ observer: @escaping () -> ()) {
        self.search(observer)
                .disposed(by: disposeBag)
    }

//    public func replace(query: SearchQuery, _ observer: @escaping () -> ()) {
//        self.searchQuery = query
//        self.more = true
//        self.from = 0
//        self.search(observer)
//                .disposed(by: disposeBag)
//    }

    private func search(_ observer: @escaping () -> ()) -> Disposable {
        if self.loading || !self.more {
            return Disposables.create()
        }

        self.loading = true
        return provider.rx.request(.search(searchQuery, searchScreen, page))
                .map { res throws -> [SearchCard] in
                    if let error = res.meta.error, let type = error.type {
                        if type == "UnsupportedException" {
                            return [SearchStaticUnsupportedCard.card]
                        } else {
                            return [SearchStaticErrorCard.create(type: .message(type, error.message))]
                        }
                    }

                    if let cards = try res.mapJSON(atKeyPath: "data") as? [[String: Any]] {
                        return cards.map({ SearchCard(dictionary: $0) })
                    }
                    return []
                }
                .subscribe({ result in
                    switch result {
                    case .success(let cards):
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
                    observer()
                })
    }

    private func append(contents cards: [SearchCard]) {
        let filtered = cards.filter {
            !self.cards.contains($0)
        }
        self.cards.append(contentsOf: filtered)
    }
}