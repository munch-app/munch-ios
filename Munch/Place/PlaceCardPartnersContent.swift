//
// Created by Fuxing Loh on 5/4/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftyJSON
import FirebaseAnalytics

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
    static let width = UIScreen.main.bounds.width - 24 - 60
    private var indexOfCellBeforeDragging = 0
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 24 + 60)

        layout.itemSize = CGSize(width: width, height: width * 0.90)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlacePartnerContentCardCell.self, forCellWithReuseIdentifier: "PlacePartnerContentCardCell")
        collectionView.register(PlacePartnerContentInstagramCardCell.self, forCellWithReuseIdentifier: "PlacePartnerContentInstagramCardCell")

        return collectionView
    }()
    private let decoder = JSONDecoder()

    private var contents: [PartnerContent] = []

    override func didLoad(card: PlaceCard) {
        let contents = try? self.decoder.decode([PartnerContent].self, from: card.data.rawData())
        self.contents = contents ?? []
        self.addSubview(collectionView)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(PlacePartnerContentCard.width * 0.90).priority(999)
            make.left.right.equalTo(self)
        }
    }

    override class var cardId: String? {
        return "extended_PartnerContent_20180405"
    }
}

extension PlacePartnerContentCard: UICollectionViewDataSource, UICollectionViewDelegate, SFSafariViewControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contents.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        Analytics.logEvent("rip_view", parameters: [
            AnalyticsParameterItemCategory: "partner_content" as NSObject
        ])

        let content = contents[indexPath.row]
        switch content.type {
        case "instagram-media":
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerContentInstagramCardCell", for: indexPath) as! PlacePartnerContentInstagramCardCell
            cell.render(content: contents[indexPath.row])
            return cell

        case "article":
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerContentCardCell", for: indexPath) as! PlacePartnerContentCardCell
            cell.render(content: contents[indexPath.row])
            return cell

        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = contents[indexPath.row]
        switch content.type {
        case "article":
            if let articleUrl = content.article?.url, let url = URL(string: articleUrl) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                self.controller.present(safari, animated: true, completion: nil)
            }

            Analytics.logEvent("rip_action", parameters: [
                AnalyticsParameterItemCategory: "click_partner_content_article" as NSObject
            ])
        case "instagram-media":
            if let username = content.instagramMedia?.username, let url = URL(string: "https://instagram.com/" + username) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                self.controller.present(safari, animated: true, completion: nil)
            }

            Analytics.logEvent("rip_action", parameters: [
                AnalyticsParameterItemCategory: "click_partner_content_instagram" as NSObject
            ])
        default: return
        }
    }

    private var collectionViewFlowLayout: UICollectionViewFlowLayout {
        return self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    private func indexOfMajorCell() -> Int {
        let itemWidth = collectionViewFlowLayout.itemSize.width
        let proportionalOffset = collectionViewFlowLayout.collectionView!.contentOffset.x / itemWidth
        return Int(round(proportionalOffset))
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        indexOfCellBeforeDragging = indexOfMajorCell()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Stop scrollView sliding:
        targetContentOffset.pointee = scrollView.contentOffset

        // calculate where scrollView should snap to:
        let indexOfMajorCell = self.indexOfMajorCell()

        // calculate conditions:
        let dataSourceCount = self.collectionView(self.collectionView, numberOfItemsInSection: 0)
        let swipeVelocityThreshold: CGFloat = 0.5 // after some trail and error
        let hasEnoughVelocityToSlideToTheNextCell = indexOfCellBeforeDragging + 1 < dataSourceCount && velocity.x > swipeVelocityThreshold
        let hasEnoughVelocityToSlideToThePreviousCell = indexOfCellBeforeDragging - 1 >= 0 && velocity.x < -swipeVelocityThreshold
        let majorCellIsTheCellBeforeDragging = indexOfMajorCell == indexOfCellBeforeDragging
        let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging && (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)

        if didUseSwipeToSkipCell {

            let snapToIndex = indexOfCellBeforeDragging + (hasEnoughVelocityToSlideToTheNextCell ? 1 : -1)
            let toValue = collectionViewFlowLayout.itemSize.width * CGFloat(snapToIndex)

            // Damping equal 1 => no oscillations => decay animation:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity.x, options: .allowUserInteraction, animations: {
                scrollView.contentOffset = CGPoint(x: toValue, y: 0)
                scrollView.layoutIfNeeded()
            }, completion: nil)

        } else {
            // This is a much better to way to scroll to a cell:
            let indexPath = IndexPath(row: indexOfMajorCell, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "swiped_partner_content" as NSObject
        ])
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
    private let authorLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 5)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.isUserInteractionEnabled = false
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
            make.height.equalTo(containerView.snp.height).dividedBy(1.625).priority(999)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(bannerImageView).inset(5)
            make.bottom.equalTo(bannerImageView).inset(5)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(bannerImageView.snp.bottom).inset(-8)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(titleLabel.snp.bottom).inset(-5)
            make.bottom.equalTo(containerView)
        }
    }

    func render(content: PartnerContent) {
        bannerImageView.render(images: content.image) { (image, error, type, url) -> Void in
            if image == nil {
                self.bannerImageView.render(named: "RIP-No-Image")
            }
        }

        titleLabel.text = content.title
        authorLabel.setTitle(content.author, for: .normal)
        descriptionLabel.text = content.description
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bannerImageView.layer.cornerRadius = 4
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PlacePartnerContentInstagramCardCell: UICollectionViewCell {
    private let bannerImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 4
        imageView.tintColor = .white
        return imageView
    }()
    private let authorLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.67)
        label.contentEdgeInsets.top = 3
        label.contentEdgeInsets.bottom = 3
        label.contentEdgeInsets.left = 4 + 5
        label.contentEdgeInsets.right = 4

        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.isUserInteractionEnabled = false

        label.tintColor = .white
        label.setImage(UIImage(named: "RIP-Partner-Instagram"), for: .normal)
        label.imageEdgeInsets.left = -5
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
        containerView.addSubview(descriptionLabel)

        containerView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }

        bannerImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView)
            make.height.equalTo(containerView.snp.height).dividedBy(1.625).priority(999)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(bannerImageView).inset(5)
            make.bottom.equalTo(bannerImageView).inset(5)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(bannerImageView.snp.bottom).inset(-8)
            make.bottom.equalTo(containerView)
        }
    }

    func render(content: PartnerContent) {
        bannerImageView.render(images: content.image) { (image, error, type, url) -> Void in
            if image == nil {
                self.bannerImageView.render(named: "RIP-No-Image")
            }
        }

        authorLabel.setTitle(content.author, for: .normal)
        descriptionLabel.text = content.description
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bannerImageView.layer.cornerRadius = 4
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}