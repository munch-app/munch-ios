//
//  PlaceShimmerCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Shimmer

class PlaceShimmerImageBannerCardView: UICollectionViewCell, PlaceCardView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let shimmerView = FBShimmeringView()
        let colorView = UIView()
        colorView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        shimmerView.contentView = colorView
        shimmerView.isShimmering = true
        self.addSubview(shimmerView)
        
        shimmerView.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
    }
    
    static var id: String {
        return "shimmer_PlaceShimmerImageBannerCardView"
    }
    
    static var height: CGFloat {
        return 200
    }
}

class PlaceShimmerNameCardView: UICollectionViewCell, PlaceCardView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let shimmerView = FBShimmeringView()
        let colorView = UIView()
        colorView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        shimmerView.contentView = colorView
        shimmerView.isShimmering = true
        self.addSubview(shimmerView)
        
        shimmerView.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
    }
    
    static var id: String {
        return "shimer_PlaceShimmerNameCardView"
    }
    
    static var height: CGFloat = 60
}
