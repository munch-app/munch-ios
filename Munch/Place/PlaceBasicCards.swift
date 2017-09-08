//
//  PlaceBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceNameCardView: UICollectionViewCell, PlaceCardView {
    @IBOutlet weak var nameLabel: UILabel!
    
    var height: CGFloat {
        return 60
    }
    
    func render(card: PlaceCard) {
        self.nameLabel.text = card["name"].stringValue
    }
}
