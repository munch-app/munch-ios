//
// Created by Fuxing Loh on 19/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SwiftyJSON
import SnapKit
import TTGTagCollectionView

class PlaceHeaderUGCCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Experimental Tags"
    }

    override class var cardId: String? {
        return "header_UGC_20180219"
    }
}

class PlaceUGCSuggestedTagCard: PlaceCardView, TTGTextTagCollectionViewDelegate {
    let tagCollection: TTGTextTagCollectionView = {
        let tagCollection = TTGTextTagCollectionView()
        tagCollection.defaultConfig = DefaultTagConfig()
        tagCollection.horizontalSpacing = 6
        tagCollection.numberOfLines = 0
        tagCollection.alignment = .left
        tagCollection.scrollDirection = .vertical
        tagCollection.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        return tagCollection
    }()

    override func didLoad(card: PlaceCard) {
        self.tagCollection.delegate = self

        let collectionHolderView = UIView()
        collectionHolderView.addSubview(tagCollection)
        self.addSubview(collectionHolderView)

        var tags = [String]()
        for (key, value): (String, JSON) in card.data {
            tags.append("\(key):\(String(format: "%.1f", value.double ?? 0))")
        }
        self.tagCollection.addTags(tags)
        self.tagCollection.reload()

        tagCollection.snp.makeConstraints { (make) in
            make.left.equalTo(collectionHolderView).inset(24)
            make.right.equalTo(collectionHolderView).inset(24)
            make.top.equalTo(collectionHolderView)
        }

        // Collection View is added because of problem with using TTGTextTagCollectionView
        collectionHolderView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(topBottom)
            make.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(self.numberOfLines(tags: tags) * 34).priority(999)
        }

        tagCollection.needsUpdateConstraints()
        tagCollection.layoutIfNeeded()
    }

    override class var cardId: String? {
        return "ugc_SuggestedTag_20180219"
    }

    class DefaultTagConfig: TTGTextTagConfig {
        override init() {
            super.init()

            tagTextFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            tagShadowOffset = CGSize.zero
            tagShadowRadius = 0
            tagCornerRadius = 3

            tagBorderWidth = 0
            tagTextColor = UIColor.black.withAlphaComponent(0.88)
            tagBackgroundColor = UIColor(hex: "ebebeb")

            tagSelectedBorderWidth = 0
            tagSelectedTextColor = UIColor.black.withAlphaComponent(0.88)
            tagSelectedBackgroundColor = UIColor(hex: "ebebeb")
            tagSelectedCornerRadius = 3

            tagExtraSpace = CGSize(width: 15, height: 8)
        }
    }

    private func numberOfLines(tags: [String]) -> Int {
        let font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        let workingWidth = UIScreen.main.bounds.width - 48

        var lines = 0
        var currentRemaining: CGFloat = 0
        for tag in tags {
            let width = UILabel.textWidth(font: font, text: tag) + 15
            if currentRemaining - width <= 0 {
                // Not Enough Space, New Line
                lines += 1
                currentRemaining = workingWidth - width - 6
            } else {
                currentRemaining = currentRemaining - width - 6
            }
        }

        if lines == 0 {
            return 1
        }
        return lines
    }
}