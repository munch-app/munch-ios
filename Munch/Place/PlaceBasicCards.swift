//
//  PlaceBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class BasicImageBannerCardView: UITableViewCell, PlaceCardView {
    let imageGradientView = UIView()
    let imageBannerView = UIImageView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        imageBannerView.contentMode = .scaleAspectFill
        imageBannerView.clipsToBounds = true
        self.addSubview(imageBannerView)
        
        imageBannerView.snp.makeConstraints { make in
            make.height.equalTo(260)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.width, height: 64)
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.backgroundColor = UIColor.clear
        
        self.addSubview(imageGradientView)
        imageGradientView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        let imageMeta = ImageMeta(json: card["image"])
        imageBannerView.render(imageMeta: imageMeta)
    }
    
    static var id: String {
        return "basic_ImageBanner_06092017"
    }
}

class BasicNameCardView: UITableViewCell, PlaceCardView {
    let nameLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        nameLabel.font = UIFont.systemFont(ofSize: 27.0, weight: UIFontWeightMedium)
        nameLabel.numberOfLines = 0
        self.addSubview(nameLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsets(topBottom: topBottom, leftRight: leftRight))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        self.nameLabel.text = card["name"].stringValue
    }
    
    static var id: String {
        return "basic_Name_06092017"
    }
}

class BasicTagCardView: UITableViewCell, PlaceCardView {
    func render(card: PlaceCard) {
        
    }
    
    static var id: String {
        return "basic_Tag_07092017"
    }
}

class BasicLocationDetailCard: UITableViewCell, PlaceCardView {
    func render(card: PlaceCard) {
        
    }
    
    static var id: String {
        return "basic_LocationDetail_07092017"
    }
}

class BasicLocationMapCard: UITableViewCell, PlaceCardView {
    func render(card: PlaceCard) {
        
    }
    
    static var id: String {
        return "basic_LocationMap_10092017"
    }
}
