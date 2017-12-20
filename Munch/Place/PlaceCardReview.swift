//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import Cosmos
import SnapKit

class PlaceHeaderReviewCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Review"
    }

    override class var cardId: String? {
        return "header_Review_20171020"
    }
}

class PlaceVendorFacebookReviewCard: PlaceCardView, SFSafariViewControllerDelegate {
    let titleLabel = UILabel()
    let ratingView = CosmosView()
    let countLabel = UILabel()

    var facebookReviewUrl: URL?

    override func didLoad(card: PlaceCard) {
        self.selectionStyle = .default
        self.addSubview(titleLabel)
        self.addSubview(ratingView)
        self.addSubview(countLabel)

        titleLabel.text = "Facebook"
        titleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom - 2)
        }

        ratingView.rating = card["overallStarRating"].double ?? 5
        ratingView.isUserInteractionEnabled = false
        ratingView.settings.fillMode = .precise
        ratingView.settings.filledColor = UIColor.init(hex: "#3B5998")
        ratingView.settings.filledBorderColor = UIColor.init(hex: "#3B5998")
        ratingView.settings.emptyColor = UIColor.clear
        ratingView.settings.emptyBorderColor = UIColor.init(hex: "#3B5998")
        ratingView.settings.starSize = 18
        ratingView.settings.starMargin = 0
        ratingView.snp.makeConstraints { (make) in
            make.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom - 2)
        }

        countLabel.text = "Based on \(card["ratingCount"].int ?? 0) reviews"
        countLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
        countLabel.textAlignment = .center
        countLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(leftRight)
            make.top.equalTo(ratingView.snp.bottom).inset(-13)
            make.bottom.equalToSuperview().inset(topBottom)
        }

        if let facebookPlaceId = card["placeId"].string {
            self.facebookReviewUrl = URL.init(string: "https://www.facebook.com/\(facebookPlaceId)/reviews")
        }
    }

    override func didTap() {
        if let url = facebookReviewUrl {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }
    }

    override class var cardId: String? {
        return "vendor_FacebookReview_20171017"
    }
}