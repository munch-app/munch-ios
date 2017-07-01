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

struct CardCollection {
    let name: String
    let query: SearchQuery?
    let items: [CardItem]
    
    /**
     Name is manadatory
     Query is optional, if nil; endless scrolling is disabled
     items is mandatory
     */
    init(name: String, query: SearchQuery?, items: [CardItem]) {
        self.name = name
        self.query = query
        self.items = items
    }
}

/**
 Extension for seperation of card collection delegate and datasource
 */
extension DiscoverTabController {
    
    func cardView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections[selectedTab].items.count
    }
    
    func cardView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cardItem: CardItem = collections[selectedTab].items[indexPath.row]
        
        if cardItem is Place {
            return DiscoverPlaceCardView.size()
        } else if cardItem is DiscoverLoadingCardView {
            return DiscoverLoadingCardView.size()
        }
        
        // Should never happen
        return CGSize()
    }
    
    func cardView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> DiscoverCardView {
        let cardItem: CardItem = collections[selectedTab].items[indexPath.row]
        
        if let place = cardItem as? Place {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverPlaceCardView", for: indexPath) as! DiscoverPlaceCardView
            cell.render(place: place)
            return cell
        } else if cardItem is DiscoverLoadingCardView {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverLoadingCardView", for: indexPath) as! DiscoverCardView
        }
        
        // Should never happen
        return DiscoverCardView()
        
    }
    
    func cardView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardItem: CardItem = collections[selectedTab].items[indexPath.row]
        
        if let place = cardItem as? Place {
            discoverDelegate.present(place: place)
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
    
    override class func height() -> CGFloat {
        return width * 0.888
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
    static let card = NoResultCardItem()
    
    override class func height() -> CGFloat {
        return 50
    }
    
    class NoResultCardItem: CardItem {}
}

/**
 Static No Location card view
 */
class DiscoverNoLocationCardView: DiscoverCardView {
    static let card = NoLocationCardItem()
    
    override class func height() -> CGFloat {
        return 100
    }
    
    @IBAction func actionEnable(_ sender: Any) {
        MunchLocation.startMonitoring()
    }
    
    class NoLocationCardItem: CardItem {}
}

/**
 Static Endless loading card view for infinity scrolling
 */
class DiscoverLoadingCardView: DiscoverCardView, CardItem {
    
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.indicatorView.color = .primary700
        self.indicatorView.startAnimating()
    }
    
    override class func height() -> CGFloat {
        return 50
    }
}

/**
 Abstract discover card cell
 */
class DiscoverCardView: UICollectionViewCell {
    static let width = UIScreen.main.bounds.width
    
    /**
     Override this for custom card view size
     Because width should always be screen bounds width
     Override height for custom height implementation
     Else it will be a square
     */
    class func size() -> CGSize {
        return CGSize(width: width, height: height())
    }
    
    class func height() -> CGFloat {
        return width
    }
}

/**
 Protocol to tell that a struct is a card viewable data
 */
protocol CardItem {
    
}
