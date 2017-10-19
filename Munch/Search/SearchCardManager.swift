//
//  SearchCollection.swift
//  Munch
//
//  Created by Fuxing Loh on 17/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation

class SearchCardManager {
    var query: SearchQuery?
    
    var topCards: [SearchCard]
    private var cardsList = [[SearchCard]]()
    
    private var loadingAppend = false
    
    var cards: [SearchCard] {
        // No Content Loaded Already
        if (cardsList.isEmpty) {
            return topCards + [SearchStaticLoadingCard.card]
        }
        
        // Last Card Contain No Result
        if (cardsList.last!.isEmpty) {
            // No Result returned by all card in list
            if (!cardsList.contains(where: { !$0.isEmpty })) {
                return topCards + [SearchStaticNoResultCard.card]
            }
            
            // No More Results
            return topCards + cardsList.reduce([], +)
        }
        
        // Else still might contain results
        return topCards + cardsList.reduce([], +) + [SearchStaticLoadingCard.card]
    }
    
    convenience init(search query: SearchQuery) {
        let shimmerCard = SearchShimmerPlaceCard.card
        self.init(query: query, cards: [], topCards: [shimmerCard, shimmerCard, shimmerCard])
        
        MunchApi.search.search(query: query) { (meta, cards) in
            if (meta.isOk()) {
                if !MunchLocation.isEnabled {
                    self.topCards = [SearchStaticNoLocationCard.card]
                }
                // TODO Render in header
            } else {
                // TODO Error Card
            }
        }
    }
    
    init(query: SearchQuery?, cards: [SearchCard], topCards: [SearchCard] = []) {
        self.query = query
        
        self.topCards = topCards
        if !cards.isEmpty {
            self.cardsList.append(cards)
        }
        
        if (self.query != nil) {
            // Query default size is 20
            self.query!.size = 20
            
            // If from is nil, set to 0
            self.query!.from = self.query!.from ?? 0
        }
    }
    
    private func append(content cards: [SearchCard]) {
        let existings = cardsList.reduce([], +)
        let filtered = cards.filter { !existings.contains($0) }
        self.cardsList.append(filtered)
    }
    
    func append(load completion: @escaping (_ meta: MetaJSON) -> Void) {
        if (query == nil || self.loadingAppend) { return }
        self.loadingAppend = true
        
        MunchApi.search.search(query: query!) { meta, cards in
            if (meta.isOk()) {
                // Update cards
                self.append(content: cards)
                self.query!.from = self.query!.from! + self.query!.size!
                
                // Set false to false
                self.loadingAppend = false
            }
            
            completion(meta)
        }
    }
}
