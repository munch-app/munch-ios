//
//  DiscoverCollection.swift
//  Munch
//
//  Created by Fuxing Loh on 16/7/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

public class CardCollection {
    var loadingNewCards = false
    
    let name: String?
    var query: SearchQuery?
    
    var topItems: [CardItem]
    var items: [CardItem]
    var botItems: [CardItem]
    
    // all items in order
    var allItems: [CardItem] { return topItems + items + botItems }
    
    /**
     Name is manadatory
     Query is optional, if nil; endless scrolling is disabled
     items is mandatory
     */
    convenience init(collection: SearchCollection) {
        let items = collection.results.filter { $0 is CardItem }.flatMap { $0 as? CardItem }
        self.init(name: collection.name, query: collection.query, items: items)
    }
    
    init(name: String?, query: SearchQuery?, topItems: [CardItem] = [], items: [CardItem] = [], botItems: [CardItem] = []) {
        self.name = name
        self.query = query
        self.topItems = topItems
        self.items = items
        self.botItems = botItems
        
        if (self.query != nil) {
            // Query size is always 15
            self.query!.size = 15
            // If from is nil, set to 0
            if (self.query!.from == nil) {
                self.query!.from = 0
            }
        }
    }
    
    /**
     Reduce to CardItems only
     */
    func append(_ results: [SearchResult]) {
        let items = results.filter { $0 is CardItem }.flatMap { $0 as? CardItem }
        append(items)
    }
    
    /**
     Appends card items to collections
     If the card item already exist, it will not be added
     */
    func append(_ items: [CardItem]) {
        // For place card item with id, only add if don't already exist
        for item in items {
            if let place = item as? Place {
                // Contains function logic
                let contains = { (i: CardItem) -> Bool in (i as? Place) == place }
                
                // Add Item if don't already exist
                if (!self.items.contains(where: contains)) {
                    self.items.append(item)
                }
            } else {
                // Add item regardlessly if is not Place
                self.items.append(item)
            }
        }
    }
}

// loadNext method with loading functions inside
extension CardCollection {
    func loadNext(completion: @escaping (_ meta: MetaJSON) -> Void) {
        // End if already loading or no query available
        if (query == nil || self.loadingNewCards) { return }
        
        self.loadingNewCards = true
        MunchApi.discovery.searchNext(query: query!) { meta, results in
            if (meta.isOk()) {
                // Append the new loaded places
                self.append(results)
                
                // Increment query from to from + size
                self.query!.from = self.query!.from! + self.query!.size!
                
                // If items return empty results, remove all bottom items
                if (results.isEmpty) {
                    self.botItems.removeAll()
                    
                    // If after loading, still empty, add a no result card
                    if (self.items.isEmpty) {
                        self.botItems.append(StaticNoResultCardItem())
                    }
                }
                
                // Flag is never set to false if meta is not ok
                self.loadingNewCards = false
            }
            
            completion(meta)
        }
        
    }
}

// Comparing 2 CardCollection is same
extension CardCollection: Equatable {
    public static func == (lhs: CardCollection, rhs: CardCollection) -> Bool {
        return lhs === rhs
    }
}

/**
 Extension for seperation of card collection delegate and datasource
 */
class CardCollectionController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var discoverDelegate: DiscoverDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    var collection = CardCollection(name: nil, query: nil, botItems: [StaticNoResultCardItem()])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        if let headerHeight = discoverDelegate?.headerHeight {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.sectionInset = UIEdgeInsets(top: headerHeight + 7, left: 0, bottom: 7, right: 0)
        }
    }
    
    /**
     Render a new card collection
     And start from y
     */
    func render(collection: CardCollection, y: CGFloat = 0) {
        self.collection = collection
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collection.allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cardItem = collection.allItems[indexPath.row]
        return cardItem.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cardItem = collection.allItems[indexPath.row]
        let cardView = collectionView.dequeueReusableCell(withReuseIdentifier: cardItem.identifier, for: indexPath)
        
        if let place = cardItem as? Place, let cardView = cardView as? DiscoverPlaceCardView {
            cardView.render(place: place)
        }
        
        return cardView
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardItem = collection.allItems[indexPath.row]
        
        if let place = cardItem as? Place {
            discoverDelegate?.present(place: place)
        }
    }
}

// Lazy loading of CardCollection
extension CardCollectionController {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cardItem = collection.allItems[indexPath.row]
        
        // If Loading CardView item is visibile lazy load more
        if cardItem is StaticLoadingCardItem {
            DispatchQueue.main.async() {
                self.lazyLoad()
            }
        }
    }
    
    /**
     This is a safe method, it will check if the collections references are still the same
     If collection is already loading it will, end the request; Can only be called once per collection
     It will only query if the query exist
     */
    func lazyLoad() {
        // Save collection reference for comparing later
        let collection = self.collection
        collection.loadNext() { meta in
            if (meta.isOk()) {
                // Check that reference is still the same
                if (self.collection === collection) {
                    self.collectionView.reloadData()
                }
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }
}

// Offset, scrolling, scroll ends
extension CardCollectionController {
    var contentOffset: CGPoint {
        return collectionView.contentOffset
    }
    
    // MARK: Scroll control
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.discoverDelegate?.collectionViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // For decelerated scrolling, scrollViewDidEndDecelerating will be called instead
        if (!decelerate) {
            self.discoverDelegate?.collectionViewDidScrollFinish(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.discoverDelegate?.collectionViewDidScrollFinish(scrollView)
    }
}
