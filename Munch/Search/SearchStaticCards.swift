//
//  DiscoverCards.swift
//  Munch
//
//  Created by Fuxing Loh on 13/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Shimmer

class SearchShimmerPlaceCard: UITableViewCell, SearchCardView {
    
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
    
    func render(card: SearchCard) {
    }
    
    static var cardId: String {
        return "shimmer_DiscoverShimmerPlaceCard"
    }
}

class SearchStaticNoLocationCard: UITableViewCell, SearchCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        let label = UILabel()
        label.text = "No Location"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightRegular)
        self.addSubview(label)
        
        let button = UIButton()
        button.setTitle("Enable Location", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightRegular)
        button.addTarget(self, action: #selector(enableLocation(button:)), for: .touchUpInside)
        self.addSubview(button)
        
        label.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            
            make.top.equalTo(self)
            make.height.equalTo(40)
        }
        
        button.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            
            make.top.equalTo(label.snp.bottom)
            make.height.equalTo(40)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    @objc func enableLocation(button: UIButton) {
        MunchLocation.scheduleOnce()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: SearchCard) {
    }
    
    static var cardId: String {
        return "static_SearchStaticNoLocationCard"
    }
}

class SearchStaticNoResultCard: UITableViewCell, SearchCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    
        let label = UILabel()
        label.text = "No Result"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightRegular)
        self.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
            
            make.height.equalTo(40)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: SearchCard) {
    }
    
    static var cardId: String {
        return "static_SearchStaticNoResultCard"
    }
}

class SearchStaticEmptyCard: UITableViewCell, SearchCardView {
    
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
    
    func render(card: SearchCard) {
    }
    
    static var cardId: String {
        return "static_SearchStaticEmptyCard"
    }
}
