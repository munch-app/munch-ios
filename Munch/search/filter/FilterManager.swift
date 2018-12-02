//
// Created by Fuxing Loh on 22/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum FilterItem {
    case rowLocation
    case rowPrice
    case rowTiming

    case tagHeader(Tag.TagType)
    case tag(Int, Tag)
    case tagLoading
    case tagMore(Tag.TagType)

    enum Location {
        case nearby
        case eatBetween
        case anywhere
        case area(Area, Bool)
    }

    enum Timing {
        case now
        case tag(Tag)
    }
}

class FilterManager {
    private let recentAreaDatabase = RecentDataDatabase<Area>(type: Area.self, name: "RecentArea", maxSize: 8)
    private let provider = MunchProvider<SearchFilterService>()

    private(set) var searchQuery: SearchQuery
    private(set) var result: FilterResult?
    private(set) var loading = true

    private var observer: AnyObserver<[FilterItem]>?
    private let disposeBag = DisposeBag()

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
    }

    func observe() -> Observable<[FilterItem]> {
        return Observable.create { (observer: AnyObserver<[FilterItem]>) in
            self.observer = observer
            self.dispatch()
            return Disposables.create()
        }
    }

    private func dispatch() {
        self.result = nil
        self.loading = true
        self.observer?.on(.next(self.collect()))

        self.provider.rx.request(.count(self.searchQuery))
                .map { response -> FilterResult in
                    return try response.map(data: FilterResult.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let result):
                        self.result = result
                        self.loading = false
                        self.observer?.on(.next(self.collect()))

                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    private func collect() -> [FilterItem] {
        var list = [FilterItem]()
        list.append(.rowLocation)
        list.append(.rowPrice)
        list.append(.rowTiming)

        list.append(contentsOf: collect(tag: .Cuisine))
        list.append(contentsOf: collect(tag: .Amenities))
        list.append(contentsOf: collect(tag: .Establishment))
        return list
    }

    private func collect(tag type: Tag.TagType) -> [FilterItem] {
        guard let tags = result?.tagGraph.tags else {
            return [.tagHeader(type), .tagLoading]
        }

        var list = [FilterItem]()
        list.append(.tagHeader(type))

        var empty = 0
        tags.filter({ $0.type == type.rawValue }).forEach { tag in
            guard tag.count > 0 else {
                empty += 1
                return
            }

            if let type = Tag.TagType(rawValue: tag.type) {
                list.append(.tag(tag.count, Tag(tagId: tag.tagId, name: tag.name, type: type)))
            }
        }

        if empty > 0 {
            list.append(.tagMore(type))
        }

        return list
    }
}

// MARK: Selectors
extension FilterManager {
    func reset() {
        self.searchQuery = SearchQuery()
        self.dispatch()
    }

    func select(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        self.dispatch()
    }

    func select(tag: Tag) {
        if let index = self.searchQuery.filter.tags.firstIndex(where: { $0.tagId == tag.tagId }) {
            self.searchQuery.filter.tags.remove(at: index)
        } else {
            self.searchQuery.filter.tags.append(tag)
        }
        self.dispatch()
    }

    func select(price: SearchQuery.Filter.Price) {
        self.searchQuery.filter.price = price
        self.dispatch()
    }

    func select(hour: SearchQuery.Filter.Hour) {
        self.searchQuery.filter.hour = hour
        self.dispatch()
    }

    func select(location type: SearchQuery.Filter.Location.LocationType) {
        self.searchQuery.filter.location.type = type
        self.searchQuery.filter.location.areas = []
        self.searchQuery.filter.location.points = []
        self.dispatch()
    }

    func select(area: Area) {
        self.searchQuery.filter.location.type = .Where
        self.searchQuery.filter.location.areas = [area]
        self.searchQuery.filter.location.points = []
        self.dispatch()
    }
}

extension FilterManager {
    static func countTitle(count: Int,
                           empty: String = "No Results".localized(),
                           prefix: String = "See".localized(),
                           postfix: String = "Restaurants".localized()) -> String {
        if count == 0 {
            return empty
        } else if count >= 100 {
            return "\(prefix) 100+ \(postfix)"
        } else if count <= 10 {
            return "\(prefix) \(count) \(postfix)"
        } else {
            let rounded = count / 10 * 10
            return "\(prefix) \(rounded)+ \(postfix)"
        }
    }
}