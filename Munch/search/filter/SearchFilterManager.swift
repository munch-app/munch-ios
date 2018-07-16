//
// Created by Fuxing Loh on 22/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import Moya
import RxSwift

enum SearchFilterType {
    case rowLocation([Location])
    case rowPrice(FilterPriceGraph?)
    case rowTime([Timing])

    case cellCategory(Category)
    case cellTag(String, Int?, Bool)
    case cellTagMore(String)

    enum Location {
        case nearby(Bool)
        case anywhere(Area, Bool)
        case area(Area, Bool)
    }

    enum Timing {
        case now(String, Bool)
        case name(String, Bool)
    }

    enum Category {
        case cuisine
        case establishment
        case amenities
        case moreCuisine

        var name: String {
            switch self {
            case .cuisine: return "Cuisine"
            case .establishment: return "Establishment"
            case .amenities: return "Amenities"
            case .moreCuisine: return "More Cuisine"
            }
        }
    }
}

struct FilterPriceGraph {
    let sorted: [(Double, Int)]
    let prices: [Double]
    let total: Int
    let min: Double
    let max: Double

    let f0: Double
    let f30: Double
    let f70: Double
    let f100: Double
}

extension FilterPriceGraph {
    static let increment: Double = 5

    init?(filterPrice: FilterPrice) {
        if filterPrice.frequency.isEmpty {
            return nil
        }

        var sorted = filterPrice.frequency
                .compactMap({ tuple -> (Double, Int)? in
                    if let price = Double(tuple.key) {
                        return (price, tuple.value)
                    }
                    return nil
                })
                .sorted(by: { (v: (Double, Int), v1: (Double, Int)) in
                    v.0 < v1.0
                })

        let total = sorted.reduce(0) { r, v in
            return r + v.1
        }

        let prices = sorted.map({ $0.0 })
        let min = ((prices.min() ?? 0) / FilterPriceGraph.increment).rounded(.down) * FilterPriceGraph.increment
        let max = ((prices.max() ?? 0) / FilterPriceGraph.increment).rounded(.up) * FilterPriceGraph.increment

        if !(sorted.contains(where: { v, i in v == min })) {
            sorted.insert((0, 0), at: 0)
        }

        if !(sorted.contains(where: { v, i in v == max })) {
            sorted.append((max, 0))
        }

        let f30 = FilterPriceGraph.sorted(sorted: sorted, count: Double(total) * 0.3) ?? 0
        let f70 = FilterPriceGraph.sorted(sorted: sorted, count: Double(total) * 0.7) ?? 0

        self.init(sorted: sorted, prices: prices, total: total,
                min: min, max: max,
                f0: min, f30: f30, f70: f70, f100: max)
    }

    fileprivate static func sorted(sorted: [(Double, Int)], count: Double) -> Double? {
        var current = count
        for (price, count) in sorted {
            current = current - Double(count)
            if current <= 0 {
                return price
            }
        }
        return nil
    }
}

extension SearchFilterType.Location {
    fileprivate static func selected(areas: [Area], searchQuery: SearchQuery) -> [SearchFilterType.Location] {
        return areas.map { area -> SearchFilterType.Location in
            if let areaId = searchQuery.filter.area?.areaId, areaId == area.areaId {
                return SearchFilterType.Location.area(area, areaId == area.areaId)
            }
            return SearchFilterType.Location.area(area, false)
        }
    }
}

extension SearchFilterType.Timing {
    fileprivate static func selected(searchQuery: SearchQuery) -> [SearchFilterType.Timing] {
        func isSelected(tag: String) -> Bool {
            return searchQuery.filter.hour.name == tag || searchQuery.filter.tag.isSelected(tag: tag)
        }

        return [
            .now("Open Now", isSelected(tag: "Open Now")),
            .name("Breakfast", isSelected(tag: "Breakfast")),
            .name("Lunch", isSelected(tag: "Lunch")),
            .name("Dinner", isSelected(tag: "Dinner")),
            .name("Supper", isSelected(tag: "Supper")),
        ]
    }

    var name: String {
        switch self {
        case .now(let name, _):
            return name
        case .name(let name, _):
            return name
        }
    }
}

extension SearchQuery.Filter.Tag {
    fileprivate mutating func select(tag: String) {
        for positive in self.positives {
            if positive.lowercased() == tag.lowercased() {
                self.positives.remove(positive)
                return
            }
        }

        positives.insert(tag)
    }

    fileprivate func isSelected(tag: String) -> Bool {
        for positive in self.positives {
            if positive.lowercased() == tag.lowercased() {
                return true
            }
        }

        return false
    }
}

extension FilterCount {
    fileprivate func getCount(tag: String) -> Int {
        for (tagC, count) in tags {
            if tagC.lowercased() == tag.lowercased() {
                return count
            }
        }
        return 0
    }
}

extension SearchFilterType.Category {
    fileprivate var tags: [String] {
        switch self {
        case .cuisine: return ["Singaporean", "Japanese", "Italian", "Thai", "Chinese", "Korean", "Mexican", "Mediterranean"]
        case .moreCuisine: return ["Chinese", "Singaporean", "Western", "Italian", "Japanese", "Indian", "Cantonese", "Thai", "Korean", "English", "Fusion", "Asian", "Hainanese", "American", "French", "Hong Kong", "Teochew", "Taiwanese", "Malaysian", "Mexican", "Shanghainese", "Indonesian", "Vietnamese", "European", "Peranakan", "Sze Chuan", "Spanish", "Middle Eastern", "Modern European", "Filipino", "Turkish", "Hakka", "German", "Mediterranean", "Swiss", "Hawaiian", "Australian"]
        case .establishment: return ["Hawker", "Drinks", "Bakery", "Dessert", "Snacks", "Cafe", "Bars & Pubs", "Fast Food", "BBQ", "Buffet", "Hotpot & Steamboat", "High Tea", "Fine Dining"]
        case .amenities: return ["Romantic", "Supper", "Brunch", "Business Meal", "Scenic View", "Child-Friendly", "Large Group", "Vegetarian Options", "Halal", "Healthy", "Alcohol", "Vegetarian", "Private Dining", "Budget", "Pet-Friendly", "Live Music", "Vegan", "Vegan Options"]
        }
    }

    fileprivate func sortedTags(searchQuery: SearchQuery, filterCount: FilterCount?) -> [SearchFilterType] {
        return self.tags.map { tag -> (String, Int?, Bool) in
            let count = filterCount?.getCount(tag: tag)
            let selected = searchQuery.filter.tag.isSelected(tag: tag)
            return (tag, count, selected)
        }.sorted { bef, aft in
            return bef.1 ?? 0 > aft.1 ?? 0
        }.map { t -> SearchFilterType in
            return SearchFilterType.cellTag(t.0, t.1, t.2)
        }
    }
}

class SearchFilterManager {
    private let recentAreaDatabase = RecentDataDatabase<Area>(type: Area.self, name: "RecentArea", maxSize: 8)
    private let provider = MunchProvider<SearchFilterService>()

    private(set) var searchQuery: SearchQuery

    private var observer: AnyObserver<[SearchFilterType]>?
    private let disposeBag = DisposeBag()

    private(set) var selectedCategory = SearchFilterType.Category.cuisine
    private(set) var filterCount: FilterCount?
    private(set) var filterPriceGraph: FilterPriceGraph?

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        self.select(category: .cuisine)
    }

    func observe() -> Observable<[SearchFilterType]> {
        return Observable.create { (observer: AnyObserver<[SearchFilterType]>) in
            self.observer = observer
            self.trigger([.price, .count])
            return Disposables.create()
        }
    }
}

extension SearchFilterManager {
    enum Trigger {
        case price
        case count
    }

    /// Call this method, don't directly call the other methods
    private func trigger(_ triggers: [Trigger] = []) {
        if triggers.contains(.price) {
            triggerPrice()
        }
        if triggers.contains(.count) {
            triggerCount()
        }
        triggerObserver()
    }

    // NOTE: Only call one of the 3 triggers.
    // triggerPrice will call triggerCount, triggerCount will call triggerObserver
    private func triggerObserver() {
        var list = [SearchFilterType]()

        let recentAreas = SearchFilterType.Location.selected(areas: recentAreaDatabase.list(), searchQuery: self.searchQuery)
        list.append(SearchFilterType.rowLocation([.nearby(isNearby), .anywhere(Area.anywhere, isAnywhere)] + recentAreas))

        list.append(SearchFilterType.rowPrice(self.filterPriceGraph))
        list.append(SearchFilterType.rowTime(SearchFilterType.Timing.selected(searchQuery: searchQuery)))

        list.append(SearchFilterType.cellCategory(selectedCategory))
        switch self.selectedCategory {
        case .cuisine:
            list.append(contentsOf: self.selectedCategory.sortedTags(searchQuery: searchQuery, filterCount: filterCount))
            list.append(.cellTagMore("CUISINE"))
        default:
            list.append(contentsOf: self.selectedCategory.sortedTags(searchQuery: searchQuery, filterCount: filterCount))
        }

        // Trigger Observer Updates
        observer?.on(.next(list))
    }

    private func triggerCount() {
        self.filterCount = nil
        provider.rx.request(.count(self.searchQuery))
                .map { response throws -> FilterCount in
                    return try response.map(data: FilterCount.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let count):
                        self.filterCount = count
                        self.triggerObserver()
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }

    private func triggerPrice() {
        self.filterPriceGraph = nil
        provider.rx.request(.price(self.searchQuery))
                .map { response throws -> FilterPrice in
                    return try response.map(data: FilterPrice.self)
                }
                .subscribe { event in
                    switch event {
                    case .success(let price):
                        self.filterPriceGraph = FilterPriceGraph(filterPrice: price)
                        self.triggerObserver()
                    case .error(let error):
                        self.observer?.on(.error(error))
                    }
                }
                .disposed(by: disposeBag)
    }
}

extension SearchFilterManager {
    func select(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        trigger([.count, .price])
    }

    func select(category: SearchFilterType.Category) {
        self.selectedCategory = category
        trigger()
    }

    func select(area: Area?, persist: Bool) {
        self.searchQuery.filter.area = area
        if let area = area, persist {
            recentAreaDatabase.add(id: area.areaId, data: area)
        }

        trigger([.count, .price])
    }

    func select(tag: String) {
        self.searchQuery.filter.tag.select(tag: tag)
        trigger([.count, .price])
    }

    func select(timing: SearchFilterType.Timing) {
        let selected = searchQuery.filter.hour.name == timing.name || searchQuery.filter.tag.isSelected(tag: timing.name)
        searchQuery.filter.hour.name = nil
        searchQuery.filter.hour.day = nil
        searchQuery.filter.hour.open = nil
        searchQuery.filter.hour.close = nil

        if selected {
            trigger([.count, .price])
            return
        }

        switch timing {
        case .now(let name, _):
            searchQuery.filter.hour.name = name

            let date = Date()
            searchQuery.filter.hour.day = Hour.Day.today.rawValue.lowercased()
            searchQuery.filter.hour.open = Hour.machineFormatter.string(from: date)
            // If time now is 23:00 onwards, OpenNow close time will be set to 23:59
            if (23 == Calendar.current.component(.hour, from: date)) {
                searchQuery.filter.hour.close = "23:59"
            } else {
                searchQuery.filter.hour.close = Hour.machineFormatter.string(from: date.addingTimeInterval(30 * 60))
            }

        case .name(let name, _):
            searchQuery.filter.hour.name = name
        }

        trigger([.count, .price])
    }

    func select(price name: String?, min: Double, max: Double) {
        searchQuery.filter.price.name = name
        searchQuery.filter.price.min = min
        searchQuery.filter.price.max = max
        trigger([.count])
    }

    func reset() {
        self.searchQuery = SearchQuery()
        trigger([.count, .price])
    }

    func reset(tags: [String]) {
        for tag in tags {
            // Delete Both Lower and Normal Case In Case of Bugs
            self.searchQuery.filter.tag.positives.remove(tag)
            self.searchQuery.filter.tag.positives.remove(tag.lowercased())
        }
        trigger([.count, .price])
    }

    func resetTiming() {
        searchQuery.filter.hour.name = nil
        searchQuery.filter.hour.day = nil
        searchQuery.filter.hour.open = nil
        searchQuery.filter.hour.close = nil
        trigger([.count, .price])
    }

    func resetPrice() {
        searchQuery.filter.price.name = nil
        searchQuery.filter.price.min = nil
        searchQuery.filter.price.max = nil
        trigger([.count])
    }
}

extension SearchFilterManager {
    private var locationName: String {
        if let areaName = searchQuery.filter.area?.name {
            return areaName
        }

        if MunchLocation.isEnabled {
            return "Nearby"
        }

        return "Singapore"
    }

    private var latLng: String? {
        if let areaLatLng = searchQuery.filter.area?.location.latLng {
            return areaLatLng
        }

        return MunchLocation.lastLatLng
    }

    private var isNearby: Bool {
        if searchQuery.filter.area != nil {
            return false
        }

        return MunchLocation.isEnabled
    }

    private var isAnywhere: Bool {
        if isNearby {
            return false
        }
        return searchQuery.filter.area == nil
    }
}