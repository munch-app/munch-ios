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

class PlaceStaticEmptyCard: UITableViewCell, PlaceCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.black
        self.snp.makeConstraints { make in
            make.height.equalTo(0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
    }
    
    static var cardId: String {
        return "static_PlaceStaticEmptyCard"
    }
}

class PlaceShimmerImageBannerCard: UITableViewCell, PlaceCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
    }
    
    static var cardId: String {
        return "shimmer_PlaceShimmerImageBannerCard"
    }
}

class PlaceShimmerNameTagCard: UITableViewCell, PlaceCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
    }
    
    static var cardId: String {
        return "shimmer_PlaceShimmerNameTagCard"
    }
}
