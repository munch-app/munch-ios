//
//  DiscoverBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SwiftRichString

class SearchPlaceCard: UITableViewCell, SearchCardView {
    let topImageView = ShimmerImageView()
    let bottomView = BottomView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        let containerView = UIView()
        containerView.addSubview(topImageView)
        containerView.addSubview(bottomView)
        self.addSubview(containerView)
        
        topImageView.layer.cornerRadius = 3
        topImageView.snp.makeConstraints { make in
            make.left.right.top.equalTo(containerView)
            make.bottom.equalTo(bottomView.snp.top)
        }
        
        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(containerView)
            make.height.equalTo(73).priority(999)
        }
        
        containerView.snp.makeConstraints { make in
            let height = (UIScreen.main.bounds.width * 0.888) - (topBottom * 2)
            make.height.equalTo(height).priority(999)
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
        let images = card["images"].flatMap {  Place.Image(json: $0.1) }
        
        topImageView.render(placeImage: images.get(0))
        bottomView.render(card: card)
    }
    
    static var cardId: String {
        return "basic_Place_20171018"
    }
    
    class BottomView: UIView {
        let nameLabel = UILabel()
        let tagLabel = UILabel()
        let locationLabel = UILabel()
        
        override init(frame: CGRect = CGRect()) {
            super.init(frame: frame)
            nameLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
            self.addSubview(nameLabel)
            
            tagLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
            tagLabel.textColor = UIColor.black.withAlphaComponent(0.75)
            self.addSubview(tagLabel)
            
            locationLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
            locationLabel.textColor = UIColor.black.withAlphaComponent(0.75)
            self.addSubview(locationLabel)
            
            nameLabel.snp.makeConstraints { make in
                make.height.equalTo(26)
                make.left.right.equalTo(self)
                make.bottom.equalTo(tagLabel.snp.top)
            }
            
            tagLabel.snp.makeConstraints { make in
                make.height.equalTo(19)
                make.left.right.equalTo(self)
                make.bottom.equalTo(locationLabel.snp.top)
            }
            
            locationLabel.snp.makeConstraints { make in
                make.height.equalTo(19)
                make.left.right.equalTo(self)
                make.bottom.equalTo(self)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(card: SearchCard) {
            nameLabel.text = card["name"].string
            render(tag: card)
            render(location: card)
        }
        
        private func render(tag card: SearchCard) {
            let tags = card["tags"].flatMap({ $0.1.string?.capitalized })
            let line = NSMutableAttributedString()
            
            // First tag
            if let firstTag = tags.get(0) {
                line.append(string: firstTag, style: Style.default {
                    $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold))
                })
            }
            
            let filteredTags = tags[1..<(tags.count < 3 ? tags.count : 3)]
            if !filteredTags.isEmpty {
                line.append(string: " • ", style: Style.default {
                    $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.ultraLight))
                })
                
                line.append(string: filteredTags.joined(separator: ", "), style: Style.default {
                    $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular))
                })
            }
            
            self.tagLabel.attributedText = line
        }
        
        private func render(location card: SearchCard) {
            let line = NSMutableAttributedString()
            
            // Street
            if let street = card["location"]["street"].string {
                line.append(NSMutableAttributedString(string: street))
            } else {
                line.append(NSMutableAttributedString(string: "Singapore"))
            }
            
            // Distance
            if let latLng = card["location"]["latLng"].string, MunchLocation.isEnabled {
                if let distance = MunchLocation.distance(asMetric: latLng) {
                    line.append(NSMutableAttributedString(string: " - \(distance)"))
                }
            }
            
            // Open Now
            let hours = card["hours"].flatMap { Place.Hour(json: $0.1) }
            if let open  = Place.Hour.Formatter.isOpen(hours: hours) {
                line.append(NSMutableAttributedString(string: " • ", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.ultraLight)]))
                if (open) {
                    let onFormat = [NSAttributedStringKey.foregroundColor: UIColor.secondary]
                    line.append(NSMutableAttributedString(string: "Open Now", attributes: onFormat))
                } else {
                    let onFormat = [NSAttributedStringKey.foregroundColor: UIColor.primary]
                    line.append(NSMutableAttributedString(string: "Closed Now", attributes: onFormat))
                }
            }
            
            self.locationLabel.attributedText = line
        }
    }
}
