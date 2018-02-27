//
// Created by Fuxing Loh on 25/12/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation

import SwiftyJSON

enum FilterType {
    case location
    case hour
    case price
    case tag(String)
    case seeMore(String, String)
}

enum LocationType {
    case nearby
    case anywhere(Location)
    case recentLocation(Location)
    case recentContainer(Container)
    case location(Location)
    case container(Container)
}

enum FilterHourType {
    case now
    case breakfast
    case lunch
    case dinner
    case supper
}

class SearchFilterManager {
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

    let recentLocationDatabase = RecentDatabase(name: "SearchLocation", maxItems: 3)
    let popularLocations: [LocationType]?
    let recentLocations: [LocationType]

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery

        self.popularLocations = SearchFilterManager.readPopularLocations()
        self.recentLocations = SearchFilterManager.readRecentLocations(database: recentLocationDatabase)
    }

    private var types: [String: [String]] = [
        "Cuisine": ["African", "American", "Arabic", "Argentinean", "Asian", "Australian", "Bangladeshi", "Beijing", "Belgian", "Brazilian", "Burmese", "Cambodian", "Cantonese", "Caribbean", "Chinese", "Cuban", "Dongbei", "Dutch", "English", "Eurasian", "European", "Foochow", "French", "Fujian", "Fusion", "German", "Greek", "Hainanese", "Hakka", "Hokkien", "Hong Kong", "Indian", "Indochinese", "International", "Iranian", "Irish", "Italian", "Japanese", "Korean", "Latin American", "Lebanese", "Malay Indonesian", "Mediterranean", "Mexican", "Middle Eastern", "Modern European", "Mongolian", "Moroccan", "Nonya Peranakan", "North Indian", "Pakistani", "Portuguese", "Russian", "Shanghainese", "Sze chuan", "Singaporean", "South Indian", "Spanish", "Swiss", "Taiwanese", "Teochew", "Thai", "Turkish", "Vietnamese", "Western", ],
        "Establishment": ["Bakery", "Buffet", "Cafe", "Dessert", "Fast Food", "Hawker", "Restaurant", "High Tea", "Drinks", "Snacks", ],
        "Amenities": ["Child-Friendly", "Vegetarian-Friendly", "Healthy", "Pet-Friendly", "Halal", "Large Group", ],
        "Occasion": ["Brunch", "Romantic", "Business Meal", "Football Screening", "Supper"]
    ]

    private var priorityTypes: [String: [String]] = [
        "Cuisine": ["Singaporean", "Japanese", "Italian", "Thai", "Chinese", "Korean", "Mexican", "Mediterranean"],
        "Establishment": ["Bars & Pubs", "Hawker", "Cafe", "Snacks"],
        "Amenities": ["Child-Friendly", "Halal", "Large Group", "Pet-Friendly", ],
        "Occasion": ["Brunch", "Romantic", "Business Meal", "Football Screening", ]
    ]

    public var items: [(String?, [FilterType])] {
        return [
            (nil, [FilterType.location]),
            (nil, [FilterType.price]),
            (nil, [FilterType.hour]),
            ("Cuisine", getPriorityTypes(type: "Cuisine").map({ FilterType.tag($0) }) + [FilterType.seeMore("Cuisine", "More Cuisines")]),
            ("Establishment", getPriorityTypes(type: "Establishment").map({ FilterType.tag($0) }) + [FilterType.seeMore("Establishment", "More Establishments")]),
            ("Amenities", getPriorityTypes(type: "Amenities").map({ FilterType.tag($0) }) + [FilterType.seeMore("Amenities", "More Amenities")]),
            ("Occasion", getPriorityTypes(type: "Occasion").map({ FilterType.tag($0) }) + [FilterType.seeMore("Occasion", "More Occasions")]),
        ]
    }

    public var locations: [LocationType] {
        return [LocationType.nearby, LocationType.anywhere(SearchFilterManager.anywhere)] + recentLocations
    }

    public var hourItems: [FilterHourType] {
        return [FilterHourType.now, FilterHourType.breakfast, FilterHourType.lunch, FilterHourType.dinner, FilterHourType.supper]
    }

    public func getMoreTypes(type: String) -> [String] {
        if let tags = types[type]?.sorted() {
            var selected = [String]()
            var sorted = tags
            for tag in searchQuery.filter.tag.positives {
                if (sorted.contains(tag)) {
                    selected.append(tag)
                    sorted.remove(at: sorted.index(of: tag)!)
                }
            }
            return selected + sorted
        }
        return []
    }

    private func getPriorityTypes(type: String) -> [String] {
        if let tags = types[type], var priorities = priorityTypes[type] {
            var selected = [String]()
            for tag in searchQuery.filter.tag.positives {
                if (tags.contains(tag)) {
                    selected.append(tag)
                    if let index = priorities.index(of: tag) {
                        priorities.remove(at: index)
                    }
                }
            }
            return selected + priorities
        }
        return []
    }

    @discardableResult func select(location: Location?, save: Bool = true) -> SearchQuery {
        if save, let name = location?.name {
            recentLocationDatabase.put(text: name, dictionary: location!.toParams())
        }
        searchQuery.filter.location = location
        searchQuery.filter.containers = []
        return searchQuery
    }

    @discardableResult func select(container: Container, save: Bool = true) -> SearchQuery {
        if save, let name = container.name {
            recentLocationDatabase.put(text: name, dictionary: container.toParams())
        }
        searchQuery.filter.location = nil
        searchQuery.filter.containers = [container]
        return searchQuery
    }

    @discardableResult func select(tag: String, selected: Bool) -> SearchQuery {
        if (selected) {
            searchQuery.filter.tag.positives.insert(tag)
        } else {
            searchQuery.filter.tag.positives.remove(tag)
        }
        return searchQuery
    }

    @discardableResult func select(hour name: String) -> SearchQuery {
        if (isSelected(hour: name)) {
            searchQuery.filter.hour.name = nil
            searchQuery.filter.hour.day = nil
            searchQuery.filter.hour.open = nil
            searchQuery.filter.hour.close = nil
        } else {
            searchQuery.filter.hour.name = name
            searchQuery.filter.hour.day = dayFormatter.string(from: Date()).lowercased()
            switch name {
            case "Open Now":
                let date = Date()
                searchQuery.filter.hour.open = timeFormatter.string(from: date)
                // If time now is 23:00 onwards, OpenNow close time will be set to 23:59
                if (23 == Calendar.current.component(.hour, from: date)) {
                    searchQuery.filter.hour.close = "23:59"
                } else {
                    searchQuery.filter.hour.close = timeFormatter.string(from: date.addingTimeInterval(30 * 60)) // 30 Minutes
                }
            case "Breakfast":
                searchQuery.filter.hour.open = "08:00"
                searchQuery.filter.hour.close = "10:15"
            case "Lunch":
                searchQuery.filter.hour.open = "11:30"
                searchQuery.filter.hour.close = "12:30"
            case "Dinner":
                searchQuery.filter.hour.open = "18:30"
                searchQuery.filter.hour.close = "20:00"
            case "Supper":
                fallthrough
            default:
                break
            }
        }
        return searchQuery
    }

    @discardableResult func select(price name: String?, min: Double?, max: Double?) -> SearchQuery {
        if let name = name, isSelected(price: name) {
            searchQuery.filter.price.name = nil
            searchQuery.filter.price.min = nil
            searchQuery.filter.price.max = nil
        } else {
            searchQuery.filter.price.name = name
            searchQuery.filter.price.min = min
            searchQuery.filter.price.max = max
        }
        return searchQuery
    }

    func resetPrice() {
        searchQuery.filter.price.name = nil
        searchQuery.filter.price.min = nil
        searchQuery.filter.price.max = nil
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
        return searchQuery.filter.hour.name == name
    }

    func isSelected(price name: String) -> Bool {
        return searchQuery.filter.price.name == name
    }

    /**
     Reset everything except for location and containers
     */
    func reset() -> SearchQuery {
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
        return searchQuery
    }

    func reset(tags: [String]) -> SearchQuery {
        for tag in tags {
            searchQuery.filter.tag.positives.remove(tag)
        }
        return searchQuery
    }
}

extension SearchFilterManager {
    public func getPriceInArea(callback: @escaping (_ meta: MetaJSON, _ priceRangeInArea: PriceRangeInArea?) -> Void) {
        MunchApi.search.priceRange(query: self.searchQuery, callback: callback)
    }
}

extension SearchFilterManager {
    class func readPopularLocations() -> [LocationType]? {
        return readJson(forResource: "locations-popular")?
                .flatMap({ Location(json: $0.1) })
                .map({ LocationType.location($0) })
    }

    class func readRecentLocations(database: RecentDatabase) -> [LocationType] {
        return database.get()
                .flatMap({ $1 })
                .flatMap({ SearchClient.parseResult(result: $0) })
                .flatMap { result in
                    if let location = result as? Location {
                        return LocationType.recentLocation(location)
                    } else if let container = result as? Container {
                        return LocationType.recentContainer(container)
                    } else {
                        return nil
                    }
                }
    }

    class func readJson(forResource resourceName: String) -> JSON? {
        if let path = Bundle.main.path(forResource: resourceName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                return try JSON(data: data)
            } catch let error {
                print("parse error: \(error.localizedDescription)")
            }
        }

        print("Invalid json file/filename/path.")
        return nil
    }

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
}