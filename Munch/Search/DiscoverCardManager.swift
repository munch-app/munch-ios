//
//  SearchCollection.swift
//  Munch
//
//  Created by Fuxing Loh on 17/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Firebase

class SearchCardManager {
    var query: SearchQuery?
    var time = Date()

    private(set) var cards: [SearchCard]
    // Whether this card manager is currently loading more content
    private var loading = false
    // Whether this card manager still contains more content to be loaded
    private(set) var more = true

    convenience init(search query: SearchQuery, completion: @escaping (_ meta: MetaJSON, _ manager: SearchCardManager) -> Void) {
        let shimmerCard = SearchShimmerPlaceCard.card
        self.init(query: query, cards: [shimmerCard, shimmerCard, shimmerCard])

        func search() {
            MunchApi.discover.discover(query: self.query!) { (meta, cards) in
                if (meta.isOk()) {
                    if (cards.isEmpty) {
                        self.cards = [SearchStaticNoResultCard.card]
                    } else {
                        self.cards = cards
                        self.query!.from = self.query!.from! + self.query!.size!
                    }
                    completion(meta, self)
                } else if meta.error?.type == "UnsupportedException" {
                    self.cards = [SearchStaticUnsupportedCard.card]
                    completion(MetaJSON.ok, self)
                } else {
                    self.cards = [SearchStaticErrorCard.create(meta: meta)]
                    completion(meta, self)
                }
            }
        }

        // Check if Location is Enabled, Inject Location
        if MunchLocation.isEnabled {
            MunchLocation.waitFor(completion: { latLng, error in
                if error != nil {
                    let meta = MetaJSON.error(type: "No Location Detected", message: "Try refreshing or moving to another spot.")
                    self.cards = [SearchStaticErrorCard.create(meta: meta)]
                    completion(meta, self)
                } else if let latLng = latLng {
                    self.query?.latLng = latLng
                    search()
                } else {
                    let meta = MetaJSON.error(type: "No Location Detected", message: "Try refreshing or moving to another spot.")
                    self.cards = [SearchStaticErrorCard.create(meta: meta)]
                    completion(meta, self)
                }
            })
        } else {
            self.query?.latLng = nil
            search()
        }
    }

    init(query: SearchQuery?, cards: [SearchCard]) {
        self.query = query
        self.cards = cards

        if (self.query != nil) {
            // Query default size is 20
            self.query!.size = 50

            // If from is nil, set to 0
            self.query!.from = self.query!.from ?? 0
        }
    }

    public func replace(query: SearchQuery) {
        self.query = query
        self.more = true
    }

    private func append(contents cards: [SearchCard]) {
        let filtered = cards.filter {
            !self.cards.contains($0)
        }
        self.cards.append(contentsOf: filtered)
    }

    func append(load completion: @escaping (_ meta: MetaJSON, _ manager: SearchCardManager) -> Void) {
        if (query == nil || self.loading) {
            return
        }
        self.loading = true

        MunchApi.discover.discover(query: query!) { meta, cards in
            if (meta.isOk()) {
                self.append(contents: cards)
                self.more = !cards.isEmpty
                self.loading = false
                self.query!.from = self.query!.from! + self.query!.size!
            } else {
                self.cards.append(SearchStaticErrorCard.create(meta: meta))
                self.more = false
                self.loading = false
            }
            completion(meta, self)
        }
    }
}

protocol SearchCardView {
    func render(card: SearchCard, controller: DiscoverController)

    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }

    static var leftRight: CGFloat { get }
    static var topBottom: CGFloat { get }

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

    // Default: Autosizing
    static func height(card: SearchCard) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    static var card: SearchCard {
        return SearchCard(cardId: cardId)
    }
}
