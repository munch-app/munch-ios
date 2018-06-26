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

class PlaceShimmerImageBannerCard: PlaceCardView {
    
    override func didLoad(card: PlaceCard) {
        let shimmerView = FBShimmeringView()
        let colorView = UIView()
        colorView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        shimmerView.contentView = colorView
        shimmerView.isShimmering = true
        self.addSubview(shimmerView)
        
        shimmerView.snp.makeConstraints { make in
            make.height.equalTo(260)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }
    }

    override class var cardId: String? {
        return "shimmer_PlaceShimmerImageBannerCard"
    }
}

class PlaceShimmerNameTagCard: PlaceCardView {
    
    override func didLoad(card: PlaceCard) {
        let shimmerView = FBShimmeringView()
        let colorView = UIView()
        colorView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        shimmerView.contentView = colorView
        shimmerView.isShimmering = true
        self.addSubview(shimmerView)
        
        shimmerView.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.edges.equalTo(self).inset(UIEdgeInsets(topBottom: topBottom, leftRight: leftRight))
        }
    }
    
    override class var cardId: String? {
        return "shimmer_PlaceShimmerNameTagCard"
    }
}

class PlaceStaticEmptyCard: PlaceCardView {
    
    override func didLoad(card: PlaceCard) {
        self.backgroundColor = UIColor.clear
        
        let view = UIView()
        self.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(1).priority(999)
            make.edges.equalTo(self)
        }
    }
    
    override class var cardId: String? {
        return "static_PlaceStaticEmptyCard"
    }
}

class PlaceStaticLastCard: PlaceCardView {
    override func didLoad(card: PlaceCard) {
        self.backgroundColor = UIColor.clear

        let view = UIView()
        self.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(leftRight - topBottom).priority(999)
            make.edges.equalTo(self)
        }
    }

    required init(card: PlaceCard = PlaceCard(cardId: PlaceStaticLastCard.cardId!), controller: PlaceController) {
        super.init(card: card, controller: controller)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var cardId: String? {
        return "static_PlaceStaticLastCard"
    }
}