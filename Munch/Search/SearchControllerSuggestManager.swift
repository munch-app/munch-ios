//
// Created by Fuxing Loh on 27/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

enum SearchSuggestType {
    case header(String)
    case location([SearchLocationType])
    case price(PriceRangeInArea)
    case priceLoading
    case time([SearchTimingType])
    case tag(Tag)
    case place(Place)
}

enum SearchLocationType {
    case nearby
    case anywhere(Location)
    case location(Location)
    case container(Container)
}

enum SearchTimingType {
    case now
    case breakfast
    case lunch
    case dinner
    case supper
}

class SearchControllerSuggestManager {
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var searchQuery: SearchQuery

    let recentLocationDatabase = RecentDatabase(name: "SearchLocation", maxItems: 8)
    private var updateHooks = [(SearchQuery) -> Void]()

    var fixedSuggestions: [SearchSuggestType] = {
        let locationDatabase = RecentDatabase(name: "SearchLocation", maxItems: 8)
        let recentLocations = SearchControllerSuggestManager.readRecentLocations(database: locationDatabase)

        var list = [SearchSuggestType]()
        list.append(SearchSuggestType.header("LOCATIONS"))
        list.append(SearchSuggestType.location([SearchLocationType.nearby, SearchLocationType.anywhere(SearchFilterManager.anywhere)] + recentLocations))
//        list.append(SearchSuggestType.header("PRICE RANGE"))
        // TODO Price Range
        list.append(SearchSuggestType.header("TIMING"))
        list.append(SearchSuggestType.time([SearchTimingType.now, SearchTimingType.breakfast, SearchTimingType.lunch, SearchTimingType.dinner, SearchTimingType.supper]))
        list.append(SearchSuggestType.header("CUISINE"))
        list.append(contentsOf: SearchControllerSuggestManager.map(type: "cuisine"))
        list.append(SearchSuggestType.header("ESTABLISHMENT"))
        list.append(contentsOf: SearchControllerSuggestManager.map(type: "establishment"))
        list.append(SearchSuggestType.header("AMENITIES"))
        list.append(contentsOf: SearchControllerSuggestManager.map(type: "amenities"))
        list.append(SearchSuggestType.header("OCCASION"))
        list.append(contentsOf: SearchControllerSuggestManager.map(type: "occasion"))
        return list
    }()

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
    }

    func addUpdateHook(hook: @escaping (SearchQuery) -> Void){
        updateHooks.append(hook)
    }

    var items: [SearchSuggestType] {
        return fixedSuggestions
    }

    private func runHooks() {
        for hook in updateHooks {
            hook(self.searchQuery)
        }
    }

    func select(location: Location?, save: Bool = true) {
        if save, let name = location?.name {
            recentLocationDatabase.put(text: name, dictionary: location!.toParams())
        }
        searchQuery.filter.location = location
        searchQuery.filter.containers = []
        runHooks()
    }

    func select(container: Container, save: Bool = true) {
        if save, let name = container.name {
            recentLocationDatabase.put(text: name, dictionary: container.toParams())
        }
        searchQuery.filter.location = nil
        searchQuery.filter.containers = [container]
        runHooks()
    }

    func select(tag: String, selected: Bool) {
        if (selected) {
            searchQuery.filter.tag.positives.insert(tag)
        } else {
            searchQuery.filter.tag.positives.remove(tag)
        }
        runHooks()
    }

    func select(hour name: String) {
        if (isSelected(hour: name)) {
            searchQuery.filter.hour.name = nil
            searchQuery.filter.hour.day = nil
            searchQuery.filter.hour.open = nil
            searchQuery.filter.hour.close = nil
            reset(tags: ["breakfast", "lunch", "dinner", "supper"])
        } else {
            switch name {
            case "Open Now":
                let date = Date()
                searchQuery.filter.hour.name = name
                searchQuery.filter.hour.day = dayFormatter.string(from: Date()).lowercased()
                searchQuery.filter.hour.open = timeFormatter.string(from: date)
                // If time now is 23:00 onwards, OpenNow close time will be set to 23:59
                if (23 == Calendar.current.component(.hour, from: date)) {
                    searchQuery.filter.hour.close = "23:59"
                } else {
                    searchQuery.filter.hour.close = timeFormatter.string(from: date.addingTimeInterval(30 * 60)) // 30 Minutes
                }
            case "Breakfast":
                select(tag: "breakfast", selected: true)
            case "Lunch":
                select(tag: "lunch", selected: true)
            case "Dinner":
                select(tag: "dinner", selected: true)
            case "Supper":
                select(tag: "supper", selected: true)
            default:
                break
            }
        }
        runHooks()
    }

    func select(price name: String?, min: Double?, max: Double?) {
        if let name = name, isSelected(price: name) {
            searchQuery.filter.price.name = nil
            searchQuery.filter.price.min = nil
            searchQuery.filter.price.max = nil
        } else {
            searchQuery.filter.price.name = name
            searchQuery.filter.price.min = min
            searchQuery.filter.price.max = max
        }
        runHooks()
    }

    func resetPrice() {
        searchQuery.filter.price.name = nil
        searchQuery.filter.price.min = nil
        searchQuery.filter.price.max = nil
        runHooks()
    }

    /**
     Reset everything except for location and containers
     */
    func reset() {
        searchQuery.filter.tag.positives = []

        // Filters Hour
        searchQuery.filter.hour.name = nil
        searchQuery.filter.hour.day = nil
        searchQuery.filter.hour.open = nil
        searchQuery.filter.hour.close = nil

        // Filters Price
        searchQuery.filter.price.name = nil
        searchQuery.filter.price.min = nil
        searchQuery.filter.price.max = nil

        // Sort
        searchQuery.sort.type = nil
        runHooks()
    }

    func reset(tags: [String]) {
        for tag in tags {
            searchQuery.filter.tag.positives.remove(tag)
        }
        runHooks()
    }

    func isSelected(tag: String) -> Bool {
        return searchQuery.filter.tag.positives.contains(tag)
    }

    func isSelected(location: Location?) -> Bool {
        if let containers = searchQuery.filter.containers, !containers.isEmpty {
            return false
        }
        return searchQuery.filter.location == location
    }

    func isSelected(container: Container) -> Bool {
        if searchQuery.filter.location == nil, let containers = searchQuery.filter.containers {
            return containers.contains(container)
        }
        return false
    }

    func isSelected(hour name: String) -> Bool {
        return searchQuery.filter.hour.name == name || searchQuery.filter.tag.positives.contains(name.lowercased())
    }

    func isSelected(price name: String) -> Bool {
        return searchQuery.filter.price.name == name
    }
}

extension SearchControllerSuggestManager {
    private static var types: [String: [String]] = [
        "cuisine": ["African", "American", "Arabic", "Argentinean", "Asian", "Australian", "Bangladeshi", "Beijing", "Belgian", "Brazilian", "Burmese", "Cambodian", "Cantonese", "Caribbean", "Chinese", "Cuban", "Dongbei", "Dutch", "English", "Eurasian", "European", "Foochow", "French", "Fujian", "Fusion", "German", "Greek", "Hainanese", "Hakka", "Hokkien", "Hong Kong", "Indian", "Indochinese", "International", "Iranian", "Irish", "Italian", "Japanese", "Korean", "Latin American", "Lebanese", "Malay Indonesian", "Mediterranean", "Mexican", "Middle Eastern", "Modern European", "Mongolian", "Moroccan", "Nonya Peranakan", "North Indian", "Pakistani", "Portuguese", "Russian", "Shanghainese", "Sze chuan", "Singaporean", "South Indian", "Spanish", "Swiss", "Taiwanese", "Teochew", "Thai", "Turkish", "Vietnamese", "Western", ],
        "establishment": ["Bakery", "Buffet", "Cafe", "Dessert", "Fast Food", "Hawker", "Restaurant", "High Tea", "Drinks", "Snacks", ],
        "amenities": ["Child-Friendly", "Vegetarian-Friendly", "Healthy", "Pet-Friendly", "Halal", "Large Group", ],
        "occasion": ["Brunch", "Romantic", "Business Meal", "Football Screening", "Supper"]
    ]

    private static var priorityTypes: [String: [String]] = [
        "cuisine": ["Singaporean", "Japanese", "Italian", "Thai", "Chinese", "Korean", "Mexican", "Mediterranean"],
        "establishment": ["Bars & Pubs", "Hawker", "Cafe", "Snacks"],
        "amenities": ["Child-Friendly", "Halal", "Large Group", "Pet-Friendly", ],
        "occasion": ["Brunch", "Romantic", "Business Meal", "Football Screening", ]
    ]

    private class func readRecentLocations(database: RecentDatabase) -> [SearchLocationType] {
        return database.get()
                .flatMap({ $1 })
                .flatMap({ SearchClient.parseResult(result: $0) })
                .flatMap { result in
                    if let location = result as? Location {
                        return SearchLocationType.location(location)
                    } else if let container = result as? Container {
                        return SearchLocationType.container(container)
                    } else {
                        return nil
                    }
                }
    }

    private class func map(type: String) -> [SearchSuggestType] {
        return priorityTypes[type.lowercased()]!.map({ SearchSuggestType.tag(Tag(name: $0)) })
    }
}
