//
//  PlaceBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceNameCardView: UITableViewCell, PlaceCardView {
    let nameLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        nameLabel.font = UIFont.systemFont(ofSize: 20.0)
        self.addSubview(nameLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
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

class PlaceImageBannerCardView: UITableViewCell, PlaceCardView {
    let imageBannerView = UIImageView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageBannerView)
        
        imageBannerView.snp.makeConstraints { make in
            make.height.equalTo(240)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0))
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
