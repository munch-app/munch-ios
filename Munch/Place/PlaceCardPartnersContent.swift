//
// Created by Fuxing Loh on 5/4/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON

class PlaceHeaderPartnerContentCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Partners Content"
        self.moreButton.isHidden = false
    }

    override func didTap() {
        let controller = PlacePartnerContentController(place: self.controller.place!)
        self.controller.navigationController!.pushViewController(controller, animated: true)
    }

    override class var cardId: String? {
        return "header_PartnerContent_20180405"
    }
}

class PlacePartnerContentCard: PlaceCardView {
    static let width = UIScreen.main.bounds.width - 24 - 24
    private let collectionView: UICollectionView = {
        let layout = SnappingCollectionViewLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 48)

        layout.itemSize = CGSize(width: width, height: width * 0.85)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlacePartnerContentCardCell.self, forCellWithReuseIdentifier: "PlacePartnerContentCardCell")

        collectionView.decelerationRate = UIScrollViewDecelerationRateFast / 4

        return collectionView
    }()

    private var contents: [JSON] = []

    override func didLoad(card: PlaceCard) {
        self.contents = card.data.array ?? []
        self.addSubview(collectionView)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        if (!contents.isEmpty) {
            collectionView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.height.equalTo(PlacePartnerContentCard.width * 0.85).priority(999)
                make.left.right.equalTo(self)
            }
        } else {
            let titleView = UILabel()
            titleView.text = "Error Loading Content"
            titleView.textColor = .primary
            self.addSubview(titleView)

            titleView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.centerX.equalTo(self)
            }
        }
    }

    override class var cardId: String? {
        return "extended_PartnerContent_20180405"
    }
}

extension PlacePartnerContentCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contents.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerContentCardCell", for: indexPath) as! PlacePartnerContentCardCell
        cell.render(json: contents[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = contents[indexPath.row]
        let controller = PlacePartnerContentController(place: self.controller.place!, startFromUniqueId: content["uniqueId"].string)
        self.controller.navigationController!.pushViewController(controller, animated: true)
    }
}

fileprivate class PlacePartnerContentCardCell: UICollectionViewCell {
    private let bannerImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 4
        imageView.tintColor = .white
        return imageView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.9)
        return label
    }()
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        label.textColor = UIColor.black.withAlphaComponent(0.55)
        return label
    }()
    private let descriptionLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)

        nameLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        nameLabel.backgroundColor = .white

        nameLabel.textContainer.maximumNumberOfLines = 3
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainer.lineFragmentPadding = 0
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 0, leftRight: 0)
        nameLabel.isUserInteractionEnabled = false
        return nameLabel
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        let containerView = UIView()
        self.addSubview(containerView)
        containerView.addSubview(bannerImageView)
        containerView.addSubview(authorLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)

        containerView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }

        bannerImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView)
            make.height.equalTo(containerView.snp.height).dividedBy(1.6).priority(999)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(bannerImageView.snp.bottom).inset(-8)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(containerView)
            make.top.equalTo(titleLabel.snp.bottom).inset(-2)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(authorLabel.snp.bottom).inset(-6)
            make.bottom.equalTo(containerView)
        }
    }

    func render(json: JSON) {
        let image = json["image"].dictionaryObject as? [String: String]
        bannerImageView.render(images: image) { (image, error, type, url) -> Void in
            if image == nil {
                self.bannerImageView.render(named: "RIP-No-Image")
            }
        }

        titleLabel.text = json["title"].string
        authorLabel.text = json["author"].string
        descriptionLabel.text = json["description"].string
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bannerImageView.layer.cornerRadius = 4
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SnappingCollectionViewLayout: UICollectionViewFlowLayout {

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }

        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalOffset = proposedContentOffset.x + collectionView.contentInset.left

        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)

        let layoutAttributesArray = super.layoutAttributesForElements(in: targetRect)

        layoutAttributesArray?.forEach({ (layoutAttributes) in
            let itemOffset = layoutAttributes.frame.origin.x
            if fabsf(Float(itemOffset - horizontalOffset)) < fabsf(Float(offsetAdjustment)) {
                offsetAdjustment = itemOffset - horizontalOffset
            }
        })

        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}