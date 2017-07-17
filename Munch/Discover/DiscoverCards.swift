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

// MARK: Dynamic card views
/**
 Card to display place content
 */
class DiscoverPlaceCardView: DiscoverCardView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    
    func render(place: Place) {
        renderFirstLine(place: place)
        renderSecondLine(place: place)
        renderThirdLine(place: place)
        
        // Render first images if exist
        imageView.render(imageMeta: place.images?.get(0))
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
            } else {
                // Temporary code: To be removed for testing only
                let format = [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold)]
                let estab = NSMutableAttributedString(string: "Restaurant", attributes: format)
                line.append(estab)
                line.append(NSMutableAttributedString(string: " • ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightUltraLight)]))
            }
        }
        
        // Tags
        if let tags = place.tags?.filter({!establishmentList.contains($0.lowercased())}) {
            if (!tags.isEmpty) {
                let format = [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular)]
                let text = tags[0..<(tags.count < 2 ? tags.count : 2)].map{ $0.capitalized }.joined(separator: ", ")
                line.append(NSMutableAttributedString(string: text, attributes: format))
            }
        }
        
        self.secondLabel.attributedText = line
    }
    
    private func renderThirdLine(place: Place) {
        let line = NSMutableAttributedString()
        
        // Street
        if let street = place.location?.street {
            line.append(NSMutableAttributedString(string: street))
        } else {
            line.append(NSMutableAttributedString(string: "Singapore"))
        }
        
        // Distance
        if let latLng = place.location?.latLng, MunchLocation.enabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(NSMutableAttributedString(string: " - \(distance)"))
            }
        }
        
        // Open Now
        if let open = place.isOpen() {
            line.append(NSMutableAttributedString(string: " • ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightUltraLight)]))
            if (open) {
                let onFormat = [NSForegroundColorAttributeName: UIColor.secondary]
                line.append(NSMutableAttributedString(string: "Open Now", attributes: onFormat))
            } else {
                let onFormat = [NSForegroundColorAttributeName: UIColor.primary]
                line.append(NSMutableAttributedString(string: "Closed Now", attributes: onFormat))
            }
        }
        
        self.thirdLabel.attributedText = line
    }
}

extension Place {
    var identifier: String {
        return "DiscoverPlaceCardView"
    }
    var height: CGFloat {
        return UIScreen.main.bounds.width * 0.888
    }
}

// MARK: Static card views
class DiscoverNoLocationCardView: DiscoverCardView {
    @IBAction func actionEnable(_ sender: Any) {
        MunchLocation.scheduleOnce()
    }
}

class DiscoverLoadingCardView: DiscoverCardView {
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.indicatorView.color = .primary700
        self.indicatorView.startAnimating()
    }
}

// MARK: Static card items
public struct StaticNoResultCardItem: CardItem {
    var identifier: String = "DiscoverNoResultCardView"
    var height: CGFloat = 50
}

public struct StaticNoLocationCardItem: CardItem {
    var identifier: String = "DiscoverNoLocationCardView"
    var height: CGFloat = 100
}

public struct StaticLoadingCardItem: CardItem {
    var identifier: String = "DiscoverLoadingCardView"
    var height: CGFloat = 50
}

// MARK: Abstract classes and protocol for card view and items
/**
 Root class for card view
 */
class DiscoverCardView: UICollectionViewCell {
    
}

/**
 Possible types are:
 - Place
 - No Result
 - No Location
 - Loading
 */
protocol CardItem: SearchResult {
    var identifier: String { get }
    var size: CGSize { get }
    var height: CGFloat { get }
}

extension CardItem {
    var size: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: self.height)
    }
}
