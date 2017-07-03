//  Everything that is placed in this file is used in discovery cards
//
//  DiscoverCards.swift
//  Munch
//
//  Created by Fuxing Loh on 22/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

let establishmentList: [String] = ["restaurant"]

class CardCollection: Equatable {
    static let placeClient = MunchClient.instance.places
    
    let name: String
    var query: SearchQuery?
    
    var topItems: [CardItem]
    var items: [CardItem]
    var botItems: [CardItem]
    
    // Combination of all items
    var allItems: [CardItem] {
        return topItems + items + botItems
    }
    
    var loading = false
    
    // Unique id of card collection for reference comparing
    private let uuid = UUID()
    
    /**
     Name is manadatory
     Query is optional, if nil; endless scrolling is disabled
     items is mandatory
     */
    init(name: String, query: SearchQuery?, topItems: [CardItem] = [], items: [CardItem] = [], botItems: [CardItem] = []) {
        self.name = name
        self.query = query
        
        if (self.query != nil) {
            // Query size is always 15
            self.query!.size = 15
            // If from is nil, set to 0
            if (self.query!.from == nil) {
                self.query!.from = 0
            }
        }
        
        self.topItems = topItems
        self.items = items
        self.botItems = botItems
    }
    
    func loadNext(completion: @escaping (_ meta: MetaJSON) -> Void) {
        if (self.loading) { return }
        
        
        // Only query if query else, safety reason
        if (query != nil) {
            // Set loading flag to true
            self.loading = true
            
            CardCollection.placeClient.searchNext(query: query!) { meta, places in
                if (meta.isOk()) {
                    // Append the new loaded places
                    self.append(places)
                    // Increment query from to from + size
                    self.query!.from = self.query!.from! + self.query!.size!
                    
                    // If places is return empty results, remove all bottom items
                    if (places.isEmpty) {
                        self.botItems.removeAll()
                        // If after loading, still empty, add a no result card
                        if (self.items.isEmpty) {
                            self.botItems.append(DiscoverNoResultCardView.card)
                        }
                    }
                    
                    // Flag is never set to false if meta is not ok
                    self.loading = false
                }
                completion(meta)
            }
        }
    }
    
    /**
     Mutating struct function
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
                if (!items.contains(where: contains)) {
                    self.items.append(item)
                }
            } else {
                // Add item regardlessly if is not Place
                self.items.append(item)
            }
        }
    }
    
    static func == (lhs: CardCollection, rhs: CardCollection) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

/**
 Extension for seperation of card collection delegate and datasource
 */
extension DiscoverTabController {
    
    /**
     Render collections view
     */
    func render(collections: [CardCollection]) {
        self.collections = collections
        self.offsetMemory = collections.map{_ in return CGPoint(x: 0, y: 0)}
        
        // Add no result or no location card view
        for collection in collections {
            if (collection.query == nil && collection.items.isEmpty) {
                // Collection with no query and items: Add no result card
                collection.botItems.append(DiscoverNoResultCardView.card)
            } else if (collection.query != nil) {
                // Collection with query: Add loading card view
                collection.botItems.append(DiscoverLoadingCardView.card)
            }
        }
        
        // Add no results card if no collections at all
        if (collections.isEmpty) {
            self.collections.append(CardCollection(name: "Result", query: nil, botItems: [DiscoverNoResultCardView.card]))
        }
        
        // Add no location card to first collection first item
        if (!MunchLocation.enabled) {
            collections[0].topItems.insert(DiscoverNoLocationCardView.card, at: 0)
        }

        
        // Reload title and tabs
        self.selectedTab = 0
        self.tabCollection.reloadData()
        self.contentCollection.reloadData()
    }
    
    func cardView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = collections[selectedTab].allItems.count
        print(count)
        return count
    }
    
    func cardView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cardItem: CardItem = collections[selectedTab].allItems[indexPath.row]
        
        if cardItem is Place {
            return DiscoverPlaceCardView.size()
        } else if cardItem is StaticCardItem {
            return (cardItem as! StaticCardItem).size()
        }
        
        // Should never happen
        print("cardView CardItem size not implemented yet")
        return CGSize()
    }
    
    func cardView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> DiscoverCardView {
        let cardItem: CardItem = collections[selectedTab].allItems[indexPath.row]
        
        if let place = cardItem as? Place {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverPlaceCardView", for: indexPath) as! DiscoverPlaceCardView
            cell.render(place: place)
            return cell
        } else if cardItem is StaticCardItem {
            let identifier = (cardItem as! StaticCardItem).identifier()
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! DiscoverCardView
        }
        
        // Should never happen
        print("cardView CardView cell not implemented yet")
        return DiscoverCardView()
        
    }
    
    func cardView(_ collectionView: UICollectionView, cellIsVisibleAt indexPath: IndexPath) {
        let cardItem = collections[selectedTab].allItems[indexPath.row]
        // If Loading CardView item is visibile lazy load more
        if cardItem is DiscoverLoadingCardView.Card {
            // Prepare function to run and then dispatch
            let loader = { self.lazyLoad(index: self.selectedTab) }
            DispatchQueue.main.async(execute: loader)
        }
    }
    
    func cardView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardItem: CardItem = collections[selectedTab].items[indexPath.row]
        
        if let place = cardItem as? Place {
            discoverDelegate.present(place: place)
        }
    }
    
    /**
     This is a safe method, it will check if the collections references are still the same
     If collection is already loading it will, end the request; Can only be called once per collection
     It will only query if the query exist
     */
    func lazyLoad(index: Int) {
        // Save collection reference for comparing later
        let collections = self.collections
        collections[index].loadNext() { meta in
            if (meta.isOk()) {
                // Check that reference is still the same
                if (self.collections == collections) {
                    // Reload content collection if selected tab is still the same
                    if (self.selectedTab == index) {
                        self.contentCollection.reloadData()
                    }
                }
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }
}

/**
 Card to display place content
 */
class DiscoverPlaceCardView: DiscoverCardView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    
    static let width = UIScreen.main.bounds.width
    
    /**
     Override this for custom card view size
     Because width should always be screen bounds width
     Override height for custom height implementation
     Else it will be a square
     */
    class func size() -> CGSize {
        return CGSize(width: width, height: width * 0.888)
    }
    
    func render(place: Place) {
        renderFirstLine(place: place)
        renderSecondLine(place: place)
        renderThirdLine(place: place)
        
        // Render images
        if let images = place.images {
            if (!images.isEmpty) {
               let types = images[0].images
                imageView.kf.setImage(with: URL(string: types.first!.value))
            }
        }
    }
    
    private func renderFirstLine(place: Place) {
        self.firstLabel.text = place.name!
    }
    
    private func renderSecondLine(place: Place) {
        let line = NSMutableAttributedString()
        
        // Establishment
        if let establishments = place.tags?.filter({establishmentList.contains($0.lowercased())}) {
            if (!establishments.isEmpty){
                let format = [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold)]
                let estab = NSMutableAttributedString(string: "\(establishments[0])", attributes: format)
                line.append(estab)
                line.append(NSMutableAttributedString(string: " • ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightUltraLight)]))
            }
        }
        
        // Tags
        if let tags = place.tags?.filter({!establishmentList.contains($0.lowercased())}) {
            if (!tags.isEmpty) {
                let format = [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular)]
                let text = tags[0..<(tags.count < 2 ? tags.count : 2)].joined(separator: ", ")
                line.append(NSMutableAttributedString(string: text, attributes: format))
            }
        }
        
        self.secondLabel.attributedText = line
    }
    
    private func renderThirdLine(place: Place) {
        let line = NSMutableAttributedString()
        
        // Address
        let address = NSMutableAttributedString(string: "73 Ayer Rajah Crescent")
        line.append(address)
        
        // Distance
        let distance = NSMutableAttributedString(string: " - 400m")
        line.append(distance)
        
        // Open Now
        let onFormat = [NSForegroundColorAttributeName: UIColor.secondary]
        line.append(NSMutableAttributedString(string: " • ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightUltraLight)]))
        line.append(NSMutableAttributedString(string: "Open Now", attributes: onFormat))
        
        self.thirdLabel.attributedText = line
    }
}

/**
 Static No Result card view
 */
class DiscoverNoResultCardView: DiscoverCardView {
    static let card = Card()
    
    class Card: StaticCardItem {
        
        override func identifier() -> String {
            return "DiscoverNoResultCardView"
        }
        
        override func height() -> CGFloat {
            return 50
        }
    }
}

/**
 Static No Location card view
 */
class DiscoverNoLocationCardView: DiscoverCardView {
    static let card = Card()
    
    @IBAction func actionEnable(_ sender: Any) {
        MunchLocation.startMonitoring()
    }
    
    class Card: StaticCardItem {
        
        override func identifier() -> String {
            return "DiscoverNoLocationCardView"
        }
        
        override func height() -> CGFloat {
            return 100
        }
    }
}

/**
 Static Endless loading card view for infinity scrolling
 */
class DiscoverLoadingCardView: DiscoverCardView {
    static let card = Card()
    
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.indicatorView.color = .primary700
        self.indicatorView.startAnimating()
    }
    
    class Card: StaticCardItem {
        
        override func identifier() -> String {
            return "DiscoverLoadingCardView"
        }
        
        override func height() -> CGFloat {
            return 50
        }
    }
}

/**
 Abstract discover card cell
 */
class DiscoverCardView: UICollectionViewCell {
    
}

/**
 Protocol to tell that a struct is a static card item with no dynamic data
 */
class StaticCardItem: CardItem {
    let width = UIScreen.main.bounds.width
    
    func identifier() -> String {
        return ""
    }
    
    /**
     Override this for custom card view size
     Because width should always be screen bounds width
     */
    func size() -> CGSize {
        return CGSize(width: width, height: height())
    }
    
    /**
     Override height for custom height implementation
     Else it will be a square
     */
    func height() -> CGFloat {
        return width
    }
}

/**
 Protocol to tell that a struct is a card viewable data
 */
protocol CardItem {
    
}
