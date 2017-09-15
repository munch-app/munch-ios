//
//  DiscoverBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchPlaceCard: UITableViewCell, SearchCardView {
    let bannerView = UIImageView()
    let bottomView = BottomView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(bannerView)
        self.addSubview(bottomView)
     
        bannerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
            make.bottom.equalTo(self)
        }
        
        bottomView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(self).inset(topBottom)
        }
        
        self.snp.makeConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.width * 0.888)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: SearchCard) {
        let place = Place(json: card["place"])
        
        let placeImage = place.images?.get(0)
        bannerView.render(placeImage: placeImage, shimmer: true)
        bottomView.render(place: place)
    }
    
    static var cardId: String {
        return "basic_Place_13092017"
    }
    
    class BottomView: UIView {
        let nameLabel = UILabel()
        let tagLabel = UILabel()
        let locationLabel = UILabel()
        
        init() {
            super.init(frame: CGRect())
            nameLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightSemibold)
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.2)
            
            tagLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
            tagLabel.textColor = UIColor.black.withAlphaComponent(0.25)
            
            locationLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular)
            locationLabel.textColor = UIColor.black.withAlphaComponent(0.25)
            
            nameLabel.snp.makeConstraints { make in
                make.height.equalTo(26)
                make.left.right.bottom.equalTo(self)
                make.top.equalTo(9)
            }
            
            tagLabel.snp.makeConstraints { make in
                make.height.equalTo(19)
                make.edges.equalTo(self)
            }
            
            locationLabel.snp.makeConstraints { make in
                make.height.equalTo(19)
                make.edges.equalTo(self)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(place: Place) {
            nameLabel.text = place.name
            render(tag: place)
            render(location: place)
        }
        
        private func render(tag place: Place) {
        
        }
        
        private func render(location place: Place) {
        
        }
    }
}
