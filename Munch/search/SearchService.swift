//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

import Moya
import RxSwift
import RealmSwift

import Crashlytics

enum SearchService {
    case search(SearchQuery, Int, Int)
    case suggest(String, SearchQuery)
}

enum SearchFilterService {
    case count(SearchQuery)
    case price(SearchQuery)
}

enum SearchFilterAreaService {
    case head
    case get
}

extension SearchService: TargetType {
    var path: String {
        switch self {
        case let .search:
            return "/search"
        case .suggest:
            return "/search/suggest"
        }
    }
    var method: Moya.Method {
        return .post
    }
    var task: Task {
        switch self {
        case let .search(searchQuery, from, size):
            return requestJSONQueryString(searchQuery, parameters: ["from": from, "size": size])
        case let .suggest(text, searchQuery):
            return .requestJSONEncodable(SearchSearchRequest(text: text, searchQuery: searchQuery))
        }
    }

    struct SearchSearchRequest: Codable {
        var text: String
        var searchQuery: SearchQuery
    }
}

extension SearchFilterService: TargetType {
    var path: String {
        switch self {
        case .count:
            return "/search/filter/count"
        case .price:
            return "/search/filter/price"
        }
    }
    var method: Moya.Method {
        return .post
    }
    var task: Task {
        switch self {
        case .count(let searchQuery):
            return .requestJSONEncodable(searchQuery)
        case .price(let searchQuery):
            return .requestJSONEncodable(searchQuery)
        }
    }
}

extension SearchFilterAreaService: TargetType {
    var path: String {
        return "/search/filter/areas"
    }
    var method: Moya.Method {
        switch self {
        case .get:
            return .get
        case .head:
            return .head
        }
    }
    var task: Task {
        return .requestPlain
    }
}

class LocalAreaData: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var updatedMillis: Int = 0
    @objc dynamic var data: Data?
}

class AreaDatabase {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let provider = MoyaProvider<SearchFilterAreaService>()

    var lastModifiedMillis: Int {
        let realm = try! Realm()
        return realm.objects(LocalAreaData.self)
                .sorted(byKeyPath: "updatedMillis", ascending: false)
                .first?.updatedMillis ?? 0
    }

    var lastRefresh: Date? {
        get {
            return UserDefaults.standard.object(forKey: "search.filter.AreaDatabase.lastRefresh") as? Date
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "search.filter.AreaDatabase.lastRefresh")
        }
    }

    func list() -> Single<[Area]> {
        return Single<[Area]>.create { single in
            let areas = self.get()

            if !areas.isEmpty {
                single(.success(areas))
            }

            // Allow skip if loaded and last refresh is within 3 days
            if !areas.isEmpty, let lastRefresh = self.lastRefresh {
                if let diff = Calendar.current.dateComponents([.hour], from: lastRefresh, to: Date()).hour, diff < 24 * 5 {
                    // Only refresh if 5 days has passed
                    return Disposables.create()
                }
            }

            let request = self.provider.rx.request(.get)
                    .map { response throws -> [Area] in
                        try response.map(data: [Area].self)
                    }
                    .subscribe { event in
                        switch event {
                        case .success(let loadedAreas):
                            if areas.isEmpty {
                                single(.success(loadedAreas))
                            }
                            self.update(areas: loadedAreas)
                        case .error(let error):
                            single(.error(error))
                        }
                    }

            return Disposables.create {
                request.dispose()
            }
        }
    }

    private func get() -> [Area] {
        self.lastRefresh = Date()
        let realm = try! Realm()

        var areas = [Area]()
        realm.objects(LocalAreaData.self)
                .sorted(byKeyPath: "name", ascending: true)
                .forEach { data in
                    if let data = data.data, let area = try? self.decoder.decode(Area.self, from: data) {
                        areas.append(area)
                    }
                }
        return areas
    }

    func update(areas: [Area]) {
        let realm = try! Realm()

        try! realm.write {
            realm.delete(realm.objects(LocalAreaData.self))

            for area in areas {
                do {
                    let data = LocalAreaData()
                    data.id = area.areaId
                    data.name = area.name
                    data.updatedMillis = area.updatedMillis ?? 0
                    data.data = try encoder.encode(area)
                    realm.add(data)
                } catch {
                    print(error)
                    Crashlytics.sharedInstance().recordError(error)
                }
            }
        }
    }
}

struct FilterPrice: Codable {
    var frequency: [String: Int]
}

struct FilterCount: Codable {
    var count: Int
    var tags: [String: Int]
}

extension SearchQuery {
    init() {
        self.init(filter: SearchQuery.Filter(), sort: SearchQuery.Sort())

        if let tags = UserSetting.instance?.search.tags {
            for tag in tags {
                filter.tag.positives.insert(tag.capitalized)
            }
        }
    }
}

struct SearchQuery: Codable {
    var filter: Filter
    var sort: Sort

    struct Filter: Codable {
        var price = Price()
        var tag = Tag()
        var hour = Hour()
        var area: Area?

        struct Price: Codable {
            var name: String?
            var min: Double?
            var max: Double?
        }

        struct Tag: Codable {
            var positives = Set<String>()
        }

        struct Hour: Codable {
            var name: String?

            var day: String?
            var open: String?
            var close: String?
        }
    }

    // See MunchCore for the available sort methods
    struct Sort: Codable, Equatable {
        var type: String?
    }
}

extension SearchQuery: Equatable {
    static func ==(lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        return lhs.filter.price.name == rhs.filter.price.name &&
                lhs.filter.price.min == rhs.filter.price.min &&
                lhs.filter.price.max == rhs.filter.price.max &&

                lhs.filter.tag.positives == rhs.filter.tag.positives &&

                lhs.filter.hour.name == rhs.filter.hour.name &&
                lhs.filter.hour.day == rhs.filter.hour.day &&
                lhs.filter.hour.open == rhs.filter.hour.open &&
                lhs.filter.hour.close == rhs.filter.hour.close &&

                lhs.filter.area?.areaId == rhs.filter.area?.areaId &&

                lhs.sort.type == rhs.sort.type
    }
}