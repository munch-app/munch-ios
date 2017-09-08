//
//  PlaceShimmerCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceShimmerImageBannerCardView: UICollectionViewCell, PlaceCardView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var height: CGFloat {
        return 200
    }
    
    func render(card: PlaceCard) {
        startShimmering()
    }
}

class PlaceShimmerNameCardView: UICollectionViewCell, PlaceCardView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var height: CGFloat {
        return 60
    }
    
    func render(card: PlaceCard) {
        startShimmering()
    }
}
