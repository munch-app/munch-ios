//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift
import RxCocoa

enum SuggestType {
    case noResult
    case loading


    case suggest(String)
    case assumption(AssumptionQueryResult)
    case place(Place)

    // Icon, SearchQuery
    case query(String, SearchQuery)
}

extension SuggestResult {
    var items: [SuggestType] {
        var items = [SuggestType]()

        // Assumption
        if let assumption = self.assumptions.get(0) {
            items.append(.assumption(assumption))
        }

        // Places
        self.places.prefix(10).forEach { place in
            items.append(.place(place))
        }

        // Suggests
        if items.isEmpty, let suggest = self.suggests.get(0) {
            items.append(.suggest(suggest))
        }

        // If No Result
        if items.isEmpty {
            items.append(.noResult)
        }
        return items
    }
}

class SuggestManager {
    private(set) var searchQuery: SearchQuery
    private(set) var loading = true

    private var observer: AnyObserver<[SuggestType]>?

    private let recent = RecentSearchQueryDatabase()
    private let provider = MunchProvider<SuggestService>()
    private let disposeBag = DisposeBag()

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
    }

    func observe() -> Observable<[SuggestType]> {
        return Observable.create { (observer: AnyObserver<[SuggestType]>) in
            self.observer = observer
            return Disposables.create()
        }
    }

    private var saves: [SuggestType] {
        var list = [SuggestType]()

        var nearby = SearchQuery()
        nearby.filter.location.type = .Nearby
        list.append(.query("Search-Suggest-Nearby", nearby))

        var anywhere = SearchQuery()
        anywhere.filter.location.type = .Anywhere
        list.append(.query("Search-Suggest-Anywhere", anywhere))

        recent.list().prefix(4).forEach { query in
            list.append(.query("Search-Suggest-Recent", query))
        }


        return list
    }

    func start(textField: UITextField) {
        textField.rx.text
                .debounce(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .flatMapFirst { s -> Observable<[SuggestType]> in
                    guard let text = s?.lowercased(), text.count > 2 else {
                        return Observable.just(self.saves)
                    }

                    self.observer?.on(.next([.loading]))
                    return self.suggest(text: text)
                }
                .subscribe { event in
                    switch event {
                    case .next(let items):
                        self.observer?.on(.next(items))

                    case .error(let error):
                        self.observer?.on(.error(error))

                    case .completed:
                        self.observer?.on(.completed)
                    }
                }.disposed(by: disposeBag)
    }

    private func suggest(text: String) -> Observable<[SuggestType]> {
        return self.provider.rx.request(.suggest(text, self.searchQuery))
                .map { res throws -> SuggestResult in
                    try res.map(data: SuggestResult.self)
                }
                .map { data -> [SuggestType] in
                    return data.items
                }
                .asObservable()
    }
}