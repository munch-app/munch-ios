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
    }

    override class var cardId: String? {
        return "header_PartnerContent_20180405"
    }
}

class PlacePartnerArticleCard: PlaceCardView {
    static let width = UIScreen.main.bounds.width - 24 - 60
    static let height = ceil(width * 0.84)
    private var indexOfCellBeforeDragging = 0
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 24 + 60)

        layout.itemSize = CGSize(width: width, height: height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlacePartnerArticleCardCell.self, forCellWithReuseIdentifier: "PlacePartnerArticleCardCell")

        return collectionView
    }()
    private let showButton: UIButton = {
        let button = UIButton()
        button.setTitle("Show all Articles", for: .normal)
        button.setTitleColor(UIColor.primary600, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()
    private var articles: [Article] = []

    override func didLoad(card: PlaceCard) {
        self.articles = card.decode([Article].self) ?? []
        self.addSubview(collectionView)
        self.addSubview(showButton)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.height.equalTo(PlacePartnerArticleCard.height).priority(999)
            make.left.right.equalTo(self)
        }

        showButton.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).inset(-topBottomLarge)
            make.bottom.equalTo(self).inset(topBottomLarge)
            make.left.right.equalTo(self).inset(leftRight)
        }

        self.showButton.addTarget(self, action: #selector(onShowButton(_:)), for: .touchUpInside)
    }

    @objc func onShowButton(_ sender: Any) {
        let controller = PlacePartnerArticleController(controller: self.controller, articles: self.articles)
        self.controller.navigationController!.pushViewController(controller, animated: true)
    }

    override class var cardId: String? {
        return "extended_PartnerArticle_20180427"
    }
}

extension PlacePartnerArticleCard: UICollectionViewDataSource, UICollectionViewDelegate, SFSafariViewControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        Analytics.logEvent("rip_view", parameters: [
            AnalyticsParameterItemCategory: "partner_content_article" as NSObject
        ])

        let article = articles[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerArticleCardCell", for: indexPath) as! PlacePartnerArticleCardCell
        cell.render(article: article)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let article = articles[indexPath.row]

        if let articleUrl = article.url, let url = URL(string: articleUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            self.controller.present(safari, animated: true, completion: nil)
        }

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_partner_content_article" as NSObject
        ])
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

fileprivate class PlacePartnerArticleCardCell: UICollectionViewCell {
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

        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(bannerImageView).inset(5)
            make.bottom.equalTo(bannerImageView).inset(5)
        }

        bannerImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView)
            make.bottom.equalTo(titleLabel.snp.top).inset(-8)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(containerView)
            make.height.equalTo(22)
            make.bottom.equalTo(descriptionLabel.snp.top).inset(-5)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.height.equalTo(48)
            make.bottom.equalTo(containerView)
        }
    }

    func render(article: Article) {
        bannerImageView.render(images: article.thumbnail) { (image, error, type, url) -> Void in
            if image == nil {
                self.bannerImageView.render(named: "RIP-No-Image")
            }
        }

        titleLabel.text = article.title
        authorLabel.setTitle(article.brand, for: .normal)
        descriptionLabel.text = article.description
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bannerImageView.layer.cornerRadius = 4
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlacePartnerInstagramCard: PlaceCardView {
    static let spacing: CGFloat = 12
    static let width = ((UIScreen.main.bounds.width - (24 * 2) - (spacing * 2)) / 3)
    static let height = width + 20
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        layout.itemSize = CGSize(width: width, height: height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = spacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlacePartnerInstagramCardCell.self, forCellWithReuseIdentifier: "PlacePartnerInstagramCardCell")
        return collectionView
    }()
    private let showButton: UIButton = {
        let button = UIButton()
        button.setTitle("Show all Instagram", for: .normal)
        button.setTitleColor(UIColor.primary600, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()
    private var medias: [InstagramMedia] = []

    override func didLoad(card: PlaceCard) {
        self.medias = card.decode([InstagramMedia].self) ?? []
        self.medias = Array(self.medias.prefix(3))
        self.addSubview(collectionView)
        self.addSubview(showButton)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)

            make.height.equalTo(PlacePartnerInstagramCard.height).priority(999)
            make.left.right.equalTo(self)
        }

        showButton.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).inset(-topBottomLarge)
            make.bottom.equalTo(self).inset(topBottomLarge)
            make.left.right.equalTo(self).inset(leftRight)
        }
        self.showButton.addTarget(self, action: #selector(onShowButton(_:)), for: .touchUpInside)
    }

    @objc func onShowButton(_ sender: Any) {
        let controller = PlacePartnerInstagramController(controller: self.controller, medias: self.medias)
        self.controller.navigationController!.pushViewController(controller, animated: true)
    }

    override class var cardId: String? {
        return "extended_PartnerInstagramMedia_20180427"
    }
}

extension PlacePartnerInstagramCard: UICollectionViewDataSource, UICollectionViewDelegate, SFSafariViewControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return medias.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        Analytics.logEvent("rip_view", parameters: [
            AnalyticsParameterItemCategory: "partner_content_instagram" as NSObject
        ])

        let media = medias[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePartnerInstagramCardCell", for: indexPath) as! PlacePartnerInstagramCardCell
        cell.render(media: media)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = PlacePartnerInstagramController(controller: self.controller, medias: self.medias)
        self.controller.navigationController!.pushViewController(controller, animated: true)

        Analytics.logEvent("rip_action", parameters: [
            AnalyticsParameterItemCategory: "click_partner_content_instagram" as NSObject
        ])
    }
}

fileprivate class PlacePartnerInstagramCardCell: UICollectionViewCell {
    private let imageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 4
        imageView.tintColor = .white
        return imageView
    }()
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        label.textColor = UIColor.black
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        let containerView = UIView()
        self.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(authorLabel)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self).inset(20)
        }

        authorLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(containerView)
        }
    }

    func render(media: InstagramMedia) {
        imageView.render(images: media.images) { (image, error, type, url) -> Void in
            if image == nil {
                self.imageView.render(named: "RIP-No-Image")
            }
        }

        authorLabel.text = "@\(media.username ?? "")"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}