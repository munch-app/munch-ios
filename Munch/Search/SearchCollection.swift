//
//  SearchCollection.swift
//  Munch
//
//  Created by Fuxing Loh on 17/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation

class SearchCollectionManager {
    static let noResultCard = SearchCard(cardId: SearchStaticNoResultCard.cardId)
    static let loadingCard = SearchCard(cardId: SearchStaticLoadingCard.cardId)
    
    let name: String
    var query: SearchQuery?
    
    private var topCards: [SearchCard]
    private var cardsList = [[SearchCard]]()
    
    private var loadingAppend = false
    
    var cards: [SearchCard] {
        // No Content Loaded Already
        if (cardsList.isEmpty) {
            return topCards + [SearchCollectionManager.loadingCard]
        }
        
        // Last Card Contain No Result
        if (cardsList.last!.isEmpty) {
            // No Result returned by all card in list
            if (cardsList.reduce(0, {$0.0 + $0.1.count}) == 0) {
                return topCards + [SearchCollectionManager.noResultCard]
            }
            
            return topCards + cardsList.reduce([], +)
        }
        
        // Else still might contain results
        return topCards + cardsList.reduce([], +) + [SearchCollectionManager.loadingCard]
    }
    
    convenience init(collection: SearchCollection) {
        self.init(name: collection.name, query: collection.query, cards: collection.cards)
    }
    
    init(name: String, query: SearchQuery?, cards: [SearchCard], topCards: [SearchCard] = []) {
        self.name = name
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
    
    func append(content cards: [SearchCard]) {
        let existings = cardsList.reduce([], +)
        let filtered = cards.filter { !existings.contains($0) }
        self.cardsList.append(filtered)
    }
    
    func append(load completion: @escaping (_ meta: MetaJSON) -> Void) {
        if (query == nil || self.loadingAppend) { return }
        self.loadingAppend = true
        
        MunchApi.search.collectionsSearch(query: query!) { meta, cards in
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
