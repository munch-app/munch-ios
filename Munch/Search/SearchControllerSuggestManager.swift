//
// Created by Fuxing Loh on 27/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

enum SearchSuggestType {
    case empty
    case loading
    case assumption(AssumedSearchQuery)
    case header(String)
    case headerMore(String)
    case location([SearchLocationType])
    case priceRange
    case time([SearchTimingType])
    case tag(Tag)
    case tagMore(String)
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

    private(set) var searchQuery: SearchQuery
    var text: String?

    let recentLocationDatabase = RecentDatabase(name: "SearchLocation", maxItems: 8)
    private var updateHooks = [(SearchQuery) -> Void]()

    lazy var suggestions: [SearchSuggestType] = {
        let locationDatabase = RecentDatabase(name: "SearchLocation", maxItems: 8)
        let recentLocations = SearchControllerSuggestManager.readRecentLocations(database: locationDatabase)

        var list = [SearchSuggestType]()
        list.append(SearchSuggestType.header("LOCATION"))
        list.append(SearchSuggestType.location([SearchLocationType.nearby, SearchLocationType.anywhere(SearchControllerSuggestManager.anywhere)] + recentLocations))
        list.append(SearchSuggestType.header("PRICE RANGE"))
        list.append(SearchSuggestType.priceRange)
        list.append(SearchSuggestType.header("TIMING"))
        list.append(SearchSuggestType.time([SearchTimingType.now, SearchTimingType.breakfast, SearchTimingType.lunch, SearchTimingType.dinner, SearchTimingType.supper]))
        list.append(SearchSuggestType.header("CUISINE"))
        list.append(contentsOf: SearchControllerSuggestManager.map(priority: "cuisine"))
        list.append(SearchSuggestType.tagMore("CUISINE"))
        list.append(SearchSuggestType.header("ESTABLISHMENT"))
        list.append(contentsOf: SearchControllerSuggestManager.map(priority: "establishment"))
        list.append(SearchSuggestType.header("AMENITIES"))
        list.append(contentsOf: SearchControllerSuggestManager.map(priority: "amenities"))
        list.append(SearchSuggestType.header("OCCASION"))
        list.append(contentsOf: SearchControllerSuggestManager.map(priority: "occasion"))
        return list
    }()

    lazy var tags: [SearchSuggestType] = {
        var list = [SearchSuggestType]()
        list.append(SearchSuggestType.header("CUISINE"))
        list.append(contentsOf: SearchControllerSuggestManager.map(all: "cuisine"))
        list.append(SearchSuggestType.header("ESTABLISHMENT"))
        list.append(contentsOf: SearchControllerSuggestManager.map(all: "establishment"))
        list.append(SearchSuggestType.header("AMENITIES"))
        list.append(contentsOf: SearchControllerSuggestManager.map(all: "amenities"))
        list.append(SearchSuggestType.header("OCCASION"))
        list.append(contentsOf: SearchControllerSuggestManager.map(all: "occasion"))
        return list
    }()

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
    }

    func setSearchQuery(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        runHooks()
    }

    func addUpdateHook(hook: @escaping (SearchQuery) -> Void) {
        updateHooks.append(hook)
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
        update(location: location, containers: [])
    }

    func select(container: Container, save: Bool = true) {
        if save, let name = container.name {
            recentLocationDatabase.put(text: name, dictionary: container.toParams())
        }
        update(location: nil, containers: [container])
    }

    private func update(location: Location?, containers: [Container]) {
        searchQuery.filter.location = location
        searchQuery.filter.containers = containers

        // Update suggestions location card
        let recentLocations = SearchControllerSuggestManager.readRecentLocations(database: recentLocationDatabase)
        suggestions[1] = SearchSuggestType.location([SearchLocationType.nearby, SearchLocationType.anywhere(SearchControllerSuggestManager.anywhere)] + recentLocations)
        runHooks()
    }

    func select(tag: String, selected: Bool) {
        if (selected) {
            searchQuery.filter.tag.positives.insert(tag)
        } else {
            reset(tags: [tag])
        }
        runHooks()
    }

    func select(hour name: String) {
        if (isSelected(hour: name)) {
            searchQuery.filter.hour.name = nil
            searchQuery.filter.hour.day = nil
            searchQuery.filter.hour.open = nil
            searchQuery.filter.hour.close = nil
            reset(tags: [name])
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
                select(tag: "Breakfast", selected: true)
            case "Lunch":
                select(tag: "Lunch", selected: true)
            case "Dinner":
                select(tag: "Dinner", selected: true)
            case "Supper":
                select(tag: "Supper", selected: true)
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
            // Delete Both Lower and Normal Case In Case of Bugs
            searchQuery.filter.tag.positives.remove(tag)
            searchQuery.filter.tag.positives.remove(tag.lowercased())
        }
        runHooks()
    }

    func isSelected(tag: String) -> Bool {
        return searchQuery.filter.tag.positives.contains(tag)
                || searchQuery.filter.tag.positives.contains(tag.lowercased())
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
        return searchQuery.filter.hour.name == name || isSelected(tag: name)
    }

    func isSelected(price name: String) -> Bool {
        return searchQuery.filter.price.name == name
    }
}

extension SearchControllerSuggestManager {
    private static var types: [String: [String]] = [
        "cuisine": ["Chinese", "Singaporean", "Western", "Italian", "Japanese", "Indian", "Cantonese", "Thai", "Korean", "English", "Fusion", "Asian", "Hainanese", "American", "French", "Hong Kong", "Teochew", "Taiwanese", "Malaysian", "Mexican", "Shanghainese", "Indonesian", "Vietnamese", "European", "Peranakan", "Sze Chuan", "Spanish", "Middle Eastern", "Modern European", "Filipino", "Turkish", "Hakka", "German", "Mediterranean", "Swiss", "Hawaiian", "Australian", "Portugese"],
        "establishment": ["Hawker", "Drinks", "Bakery", "Dessert", "Snacks", "Cafe", "Bars & Pubs", "Fast Food", "BBQ", "Buffet", "Hotpot & Steamboat", "High Tea", "Fine Dining"],
        "amenities": ["Child-Friendly", "Large Group", "Vegetarian Options", "Halal", "Healthy", "Alcohol", "Vegetarian", "Private Dining", "Budget", "Pet-Friendly", "Live Music", "Vegan", "Vegan Options"],
        "occasion": ["Romantic", "Supper", "Brunch", "Business Meal", "Scenic View"]
    ]

    private static var priorityTypes: [String: [String]] = [
        "cuisine": ["Singaporean", "Japanese", "Italian", "Thai", "Chinese", "Korean", "Mexican", "Mediterranean"],
        "establishment": ["Hawker", "Drinks", "Bakery", "Dessert", "Snacks", "Cafe", "Bars & Pubs", "Fast Food", "BBQ", "Buffet", "Hotpot & Steamboat", "High Tea", "Fine Dining"],
        "amenities": ["Child-Friendly", "Large Group", "Vegetarian Options", "Halal", "Healthy", "Alcohol", "Vegetarian", "Private Dining", "Budget", "Pet-Friendly", "Live Music", "Vegan", "Vegan Options"],
        "occasion": ["Romantic", "Supper", "Brunch", "Business Meal", "Scenic View"]
    ]

    public static var anywhere: Location {
        var singapore = Location()
        singapore.id = "singapore"
        singapore.name = "Singapore"
        singapore.country = "singapore"
        singapore.city = "singapore"
        singapore.latLng = "1.290270, 103.851959"
        singapore.points = ["1.26675774823,103.603134155", "1.32442122318,103.617553711", "1.38963424766,103.653259277", "1.41434608581,103.666305542", "1.42944763543,103.671798706", "1.43905766081,103.682785034", "1.44386265833,103.695831299", "1.45896401284,103.720550537", "1.45827758983,103.737716675", "1.44935407163,103.754196167", "1.45004049736,103.760375977", "1.47887018872,103.803634644", "1.4754381021,103.826980591", "1.45827758983,103.86680603", "1.43219336108,103.892211914", "1.4287612035,103.897018433", "1.42670190649,103.915557861", "1.43219336108,103.934783936", "1.42189687297,103.960189819", "1.42464260763,103.985595703", "1.42121043879,104.000701904", "1.43974408965,104.02130127", "1.44592193988,104.043960571", "1.42464260763,104.087219238", "1.39718511473,104.094772339", "1.35737118164,104.081039429", "1.29009788407,104.127044678", "1.277741368,104.127044678", "1.25371463932,103.982162476", "1.17545464492,103.812561035", "1.13014521522,103.736343384", "1.19055762617,103.653945923", "1.1960495989,103.565368652", "1.26675774823,103.603134155"]
        return singapore
    }

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

    private class func map(priority type: String) -> [SearchSuggestType] {
        return priorityTypes[type.lowercased()]!.map({ SearchSuggestType.tag(Tag(name: $0)) })
    }

    private class func map(all type: String) -> [SearchSuggestType] {
        return types[type.lowercased()]!.map({ SearchSuggestType.tag(Tag(name: $0)) })
    }

    class func map(assumptions: [AssumedSearchQuery], places: [Place], locationContainers: [SearchResult], tags: [Tag]) -> [SearchSuggestType] {
        var list = [SearchSuggestType]()

        for query in assumptions {
            list.append(.assumption(query))
        }

        if !locationContainers.isEmpty {
            list.append(.header("LOCATION"))
            list.append(SearchSuggestType.location(locationContainers.flatMap({
                if let location = $0 as? Location {
                    return SearchLocationType.location(location)
                } else if let container = $0 as? Container {
                    return SearchLocationType.container(container)
                } else {
                    return nil
                }
            })))
        }

        if !tags.isEmpty {
            list.append(.header("TAG"))
            list.append(contentsOf: tags.map({ SearchSuggestType.tag($0) }))
        }

        if !places.isEmpty {
            list.append(.header("RESTAURANT"))
            list.append(contentsOf: places.map({ SearchSuggestType.place($0) }))
        }

        if list.isEmpty {
            list.append(.empty)
        }

        return list
    }
}

extension SearchControllerSuggestManager {
    public func getPriceInArea(callback: @escaping (_ meta: MetaJSON, _ priceRangeInArea: PriceRangeInArea?) -> Void) {
        MunchApi.search.suggestPriceRange(query: self.searchQuery, callback: callback)
    }

    public func getLocationName() -> String {
        if let containers = searchQuery.filter.containers, !containers.isEmpty {
            for container in containers {
                if let name = container.name {
                    return name
                }
            }
        }

        if let locationName = searchQuery.filter.location?.name {
            return locationName
        }

        if MunchLocation.isEnabled {
            return "Nearby"
        }

        return "Singapore"
    }

    public func getContextLatLng() -> String? {
        if let containers = searchQuery.filter.containers, !containers.isEmpty {
            for container in containers {
                if let latLng = container.location?.latLng {
                    return latLng
                }
            }
        }

        if let latLng = searchQuery.filter.location?.latLng {
            return latLng
        }

        if MunchLocation.isEnabled {
            return MunchLocation.lastLatLng
        }

        return nil
    }
}
