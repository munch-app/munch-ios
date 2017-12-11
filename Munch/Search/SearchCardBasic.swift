//
//  DiscoverBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON
import SwiftRichString
import TTGTagCollectionView

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
            make.height.equalTo(75).priority(999)
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
        let images = card["images"].flatMap {
            Place.Image(json: $0.1)
        }

        topImageView.render(placeImage: images.get(0))
        bottomView.render(card: card)
        setNeedsLayout()
        layoutIfNeeded()
    }

    static var cardId: String {
        return "basic_Place_20171211"
    }

    class BottomView: UIView {
        let nameLabel = UILabel()
        let tagLabel = UILabel()
        let tagCollection = TTGTextTagCollectionView()
        let locationLabel = UILabel()

        override init(frame: CGRect = CGRect()) {
            super.init(frame: frame)
            self.addSubview(nameLabel)
            self.addSubview(tagLabel)
            self.addSubview(tagCollection)
            self.addSubview(locationLabel)

            nameLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
            nameLabel.snp.makeConstraints { make in
                make.height.equalTo(26)
                make.left.right.equalTo(self)
                make.bottom.equalTo(tagLabel.snp.top)
            }

            tagLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
            tagLabel.textColor = UIColor.black.withAlphaComponent(0.75)
            tagLabel.snp.makeConstraints { make in
                make.height.equalTo(23)
                make.left.equalTo(self)
                make.bottom.equalTo(locationLabel.snp.top).inset(-1)
            }

            tagCollection.defaultConfig = DefaultTagConfig()
            tagCollection.isUserInteractionEnabled = false
            tagCollection.horizontalSpacing = 8
            tagCollection.verticalSpacing = 0
            tagCollection.numberOfLines = 0
            tagCollection.alignment = .left
            tagCollection.scrollDirection = .horizontal
            tagCollection.showsHorizontalScrollIndicator = false
            tagCollection.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            tagCollection.snp.makeConstraints { (make) in
                make.left.equalTo(tagLabel.snp.right)
                make.right.equalTo(self)
                make.bottom.equalTo(locationLabel.snp.top).inset(-1)
            }

            locationLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
            locationLabel.textColor = UIColor.black.withAlphaComponent(0.75)
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
            if let average = card["review"]["average"].double {
                tagLabel.attributedText = ReviewRatingUtils.create(percent: CGFloat(average), fontSize: 15.0)
                tagCollection.contentInset.left = 8
            } else {
                tagLabel.text = nil
                tagCollection.contentInset.left = 0
            }

            tagCollection.removeAllTags()
            let tags = card["tags"].flatMap({ $0.1.string?.capitalized }).prefix(3)
            tagCollection.addTags(Array(tags))
            tagCollection.reload()
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
            let hours = card["hours"].flatMap {
                Place.Hour(json: $0.1)
            }
            if let open = Place.Hour.Formatter.isOpen(hours: hours) {
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


        class DefaultTagConfig: TTGTextTagConfig {
            override init() {
                super.init()

                tagTextFont = UIFont.systemFont(ofSize: 13.0, weight: .regular)
                tagShadowOffset = CGSize.zero
                tagShadowRadius = 0
                tagCornerRadius = 3

                tagBorderWidth = 0
                tagTextColor = UIColor.black.withAlphaComponent(0.88)
                tagBackgroundColor = UIColor(hex: "ebebeb")

                tagExtraSpace = CGSize(width: 14, height: 7)
            }
        }
    }
}