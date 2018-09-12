//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import SwiftyJSON
import Moya
import RxSwift

import Firebase
import Crashlytics

private let shimmerCards: [SearchCard] = {
    let shimmerCard = SearchShimmerPlaceCard.card
    return [shimmerCard, shimmerCard, shimmerCard]
}()

class SearchCardManager {
    private let provider = MunchProvider<SearchService>()
    private var from: Int = 0
    private let size: Int = 30

    let disposeBag = DisposeBag()
    var searchQuery: SearchQuery
    let startDate = Date()

    fileprivate(set) var cards: [SearchCard] = shimmerCards
    // Whether this card manager is currently loading more content
    fileprivate(set) var loading = false
    // Whether this card manager still contains more content to be loaded
    fileprivate(set) var more = true

    init(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
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

    public func replace(query: SearchQuery, _ observer: @escaping () -> ()) {
        self.searchQuery = query
        self.more = true
        self.from = 0
        self.search(observer)
                .disposed(by: disposeBag)
    }

    private func search(_ observer: @escaping () -> ()) -> Disposable {
        if self.loading || !self.more {
            return Disposables.create()
        }

        self.loading = true
        return provider.rx.request(.search(searchQuery, from, size))
                .map { response throws -> [SearchCard] in
                    if let error = response.meta.error, let type = error.type {
                        if type == "UnsupportedException" {
                            return [SearchStaticUnsupportedCard.card]
                        } else {
                            return [SearchStaticErrorCard.create(type: .message(type, error.message))]
                        }
                    }

                    if let res = try response.mapJSON() as? [String: Any], let cards = res["data"] as? [[String: Any]], !cards.isEmpty {
                        return cards.map({ SearchCard(dictionary: $0) })
                    }
                    return [SearchStaticNoResultCard.card]
                }
                .subscribe({ result in
                    if self.from == 0 {
                        self.cards = []
                    }

                    switch result {
                    case .success(let cards):
                        self.append(contents: cards)
                        self.more = !cards.isEmpty
                        self.from += self.size

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

protocol SearchCardView {
    func render(card: SearchCard, controller: SearchController)

    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }

    static var leftRight: CGFloat { get }
    static var topBottom: CGFloat { get }
    static var width: CGFloat { get }
    static var middleWidth: CGFloat { get }

    // Height for card view
    static func height(card: SearchCard) -> CGFloat

    static var cardId: String { get }
}

extension SearchCardView {
    var leftRight: CGFloat {
        return 24.0
    }

    var topBottom: CGFloat {
        return 16.0
    }

    static var leftRight: CGFloat {
        return 24.0
    }

    static var topBottom: CGFloat {
        return 16.0
    }

    static var width: CGFloat {
        return UIScreen.main.bounds.width
    }

    static var middleWidth: CGFloat {
        return width - (leftRight * 2)
    }

    // Default: Autosizing
    static func height(card: SearchCard) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    static var card: SearchCard {
        return SearchCard(cardId: cardId)
    }
}

/**
 Search typed Cards
 Access json through the subscript
 */
struct SearchCard {
    private static let decoder = JSONDecoder()

    var cardId: String
    var uniqueId: String?
    var instanceId: String

    private var dictionary: [String: Any]

    init(cardId: String, dictionary: [String: Any] = [:]) {
        self.cardId = cardId
        self.instanceId = String(arc4random())
        self.dictionary = dictionary
    }

    init(dictionary: [String: Any]) {
        self.dictionary = dictionary
        self.cardId = dictionary["_cardId"] as! String
        self.uniqueId = dictionary["_uniqueId"] as? String
        self.instanceId = String(arc4random())
    }

    subscript(name: String) -> Any? {
        return dictionary[name]
    }
}

// Helper Method
extension SearchCard {
    func string(name: String) -> String? {
        return self[name] as? String
    }

    func int(name: String) -> Int? {
        return self[name] as? Int
    }

    func decode<T>(name: String, _ type: T.Type) -> T? where T: Decodable {
        do {
            if let dict = self[name] {
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try SearchCard.decoder.decode(type, from: data)
            }
        } catch {
            print(error)
            Crashlytics.sharedInstance().recordError(error)
        }
        return nil
    }
}

extension SearchCard: Equatable {
    static func ==(lhs: SearchCard, rhs: SearchCard) -> Bool {
        return lhs.cardId == rhs.cardId && lhs.uniqueId == rhs.uniqueId
    }
}
