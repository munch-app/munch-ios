//
//  SearchCollection.swift
//  Munch
//
//  Created by Fuxing Loh on 17/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchCardManager {
    var query: SearchQuery?
    
    private(set) var cards: [SearchCard]
    private var loadingAppend = false
    
    convenience init(search query: SearchQuery, completion: @escaping (_ meta: MetaJSON) -> Void) {
        let shimmerCard = SearchShimmerPlaceCard.card
        self.init(query: query, cards: [shimmerCard, shimmerCard, shimmerCard])
        
        MunchApi.search.search(query: query) { (meta, cards) in
            if (meta.isOk()) {
                if (cards.isEmpty) {
                    self.cards = [SearchStaticNoResultCard.card]
                } else {
                    self.cards = cards + [SearchStaticLoadingCard.card]
                }
            } else {
                // TODO Error Card??
            }
            completion(meta)
        }
    }
    
    init(query: SearchQuery?, cards: [SearchCard]) {
        self.query = query
        self.cards = cards
        
        if (self.query != nil) {
            // Query default size is 20
            self.query!.size = 20
            
            // If from is nil, set to 0
            self.query!.from = self.query!.from ?? 0
        }
    }
    
    private func append(contents cards: [SearchCard]) {
        let filtered = cards.filter { !cards.contains($0) }
        self.cards.append(contentsOf: filtered)
    }
    
    func append(load completion: @escaping (_ meta: MetaJSON) -> Void) {
        if (query == nil || self.loadingAppend) { return }
        self.loadingAppend = true
        
        MunchApi.search.search(query: query!) { meta, cards in
            if (meta.isOk()) {
                // Update cards
                self.cards.removeLast()
                if (!cards.isEmpty) {
                    self.append(contents: cards)
                    self.cards.append(SearchStaticLoadingCard.card)
                }
                
                self.loadingAppend = false
                self.query!.from = self.query!.from! + self.query!.size!
            } else {
                // TODO Error Card??
            }
            completion(meta)
        }
    }
}

protocol SearchCardView {
    func render(card: SearchCard)
    
    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }
    
    static var cardId: String { get }
}

extension SearchCardView {
    var leftRight: CGFloat {
        return 24.0
    }
    
    var topBottom: CGFloat {
        return 16.0
    }
    
    static var card: SearchCard {
        return SearchCard(cardId: cardId)
    }
}
