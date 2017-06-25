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


/**
 Title cell for Discovery Page
 */
class DiscoverTabTitleCell: UICollectionViewCell {
    static let titleFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
    
    @IBOutlet weak var label: UILabel!
    
    func render(title: String, selected: Bool) {
        self.label.text = title
        if (selected) {
            label.textColor = UIColor.black.withAlphaComponent(0.8)
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.35)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func render(place: Place) {
        
    }
}

/**
 Abstract discover card cell
 */
class DiscoverCardView: UICollectionViewCell {

    
}
