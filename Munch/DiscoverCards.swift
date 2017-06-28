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

let establishmentList: [String] = ["restaurant"]

/**
 Title cell for Discovery Page
 */
class DiscoverTabTitleCell: UICollectionViewCell {
    static let titleFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIView!
    
    func render(title: String, selected: Bool) {
        self.label.text = title.uppercased()
        if (selected) {
            label.textColor = UIColor.black.withAlphaComponent(0.8)
            indicator.backgroundColor = .primary300
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.35)
            indicator.backgroundColor = .white
        }
    }
    
    class func width(title: String) -> CGSize {
        let width = UILabel.textWidth(font: titleFont, text: title)
        return CGSize(width: width + 20, height: 50)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
        
        // Address
        let address = NSMutableAttributedString(string: "73 Ayer Rajah Crescent")
        line.append(address)
        
        // Distance
        let distance = NSMutableAttributedString(string: " - 400m")
        line.append(distance)
        
        self.secondLabel.attributedText = line
    }
    
    private func renderThirdLine(place: Place) {
        let line = NSMutableAttributedString()
        let seperatorFormat = [NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightUltraLight)]
        
        // Establishment
        if let establishments = place.tags?.filter({establishmentList.contains($0.lowercased())}) {
            if (!establishments.isEmpty){
                let format = [NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)]
                let estab = NSMutableAttributedString(string: "\(establishments[0])", attributes: format)
                line.append(estab)
                line.append(NSMutableAttributedString(string: " • ", attributes: seperatorFormat))
            }
        }
        
        // Tags
        if let tags = place.tags?.filter({!establishmentList.contains($0.lowercased())}) {
            if (!tags.isEmpty) {
                let format = [NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular)]
                let text = tags[0..<(tags.count < 2 ? tags.count : 2)].joined(separator: ", ")
                line.append(NSMutableAttributedString(string: text, attributes: format))
                line.append(NSMutableAttributedString(string: " • ", attributes: seperatorFormat))
            }
        }
        
        // Open Now
        let onFormat = [NSForegroundColorAttributeName: UIColor.secondary]
        line.append(NSMutableAttributedString(string: "Open Now", attributes: onFormat))
        
        self.thirdLabel.attributedText = line
    }
}

/**
 Abstract discover card cell
 */
class DiscoverCardView: UICollectionViewCell {

    
}
