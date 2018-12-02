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

//class SuggestManager {
//    private let provider = MunchProvider<SuggestService>()
//    private let disposeBag = DisposeBag()
//
//    func start(textField: UITextField, _ on: @escaping (Event<[SuggestType]>) -> Void) {
//        textField.rx.text
//                .debounce(0.3, scheduler: MainScheduler.instance)
//                .distinctUntilChanged()
//                .flatMapFirst { s -> Observable<[SuggestType]> in
//                    guard let text = s?.lowercased(), text.count > 2 else {
//                        return Observable.just([.rowRecent])
//                    }
//
//                    self.items = [.loading]
//                    self.tableView.reloadData()
//
//                    return self.provider.rx.request(.suggest(text, self.searchQuery))
//                            .map { res throws -> SuggestResult in
//                                try res.map(data: SuggestResult.self)
//                            }
//                            .map { data -> [SuggestType] in
//                                return data.items
//                            }
//                            .asObservable()
//                }
//                .catchError { (error: Error) in
//                    self.alert(error: error)
//                    return Observable.empty()
//                }
//                .subscribe { event in
//                    switch event {
//                    case .next(let items):
//                        self.items = items
//                        self.tableView.reloadData()
//
//                    case .error(let error):
//                        self.alert(error: error)
//
//                    case .completed:
//                        return
//                    }
//                }
//                .disposed(by: disposeBag)
//    }
//}