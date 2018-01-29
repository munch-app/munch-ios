//
//  PlaceCardArticle.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftyJSON

class PlaceHeaderArticleCard: PlaceTitleCardView {
    override func didLoad(card: PlaceCard) {
        self.title = "Notable Articles"
        self.moreButton.isHidden = false
    }

    override func didTap() {
        let controller = PlaceDataViewController(place: self.controller.place!, selected: "ARTICLES")
        self.controller.navigationController!.pushViewController(controller, animated: true)
    }

    override class var cardId: String? {
        return "header_Article_20171112"
    }
}

class PlaceVendorArticleCard: PlaceCardView {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 150, height: 160)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PlaceVendorArticleCardCell.self, forCellWithReuseIdentifier: "PlaceVendorArticleCardCell")
        return collectionView
    }()

    private var articles = [Article]()

    override func didLoad(card: PlaceCard) {
        self.articles = card.data.map({ Article(json: $0.1) })
        self.addSubview(collectionView)

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        if (!articles.isEmpty) {
            collectionView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.height.equalTo(160)
                make.left.right.equalTo(self)
            }
        } else {
            let titleView = UILabel()
            titleView.text = "Error Loading Articles"
            titleView.textColor = .primary
            self.addSubview(titleView)

            titleView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self).inset(topBottom)
                make.centerX.equalTo(self)
            }
        }
    }

    override class var cardId: String? {
        return "vendor_Article_20171029"
    }
}

extension PlaceVendorArticleCard: UICollectionViewDataSource, UICollectionViewDelegate, SFSafariViewControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceVendorArticleCardCell", for: indexPath) as! PlaceVendorArticleCardCell
        cell.render(article: articles[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let articleUrl = articles[indexPath.row].url, let url = URL(string: articleUrl) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }
    }
}

fileprivate class PlaceVendorArticleCardCell: UICollectionViewCell {
    private let articleImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.layer.cornerRadius = 2
        imageView.tintColor = .white
        return imageView
    }()
    private let articleTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        label.textColor = UIColor.black.withAlphaComponent(0.85)
        return label
    }()
    private let articleBrandLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 10.0, weight: .regular)
        label.setTitleColor(.white, for: .normal)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.66)
        label.contentEdgeInsets = UIEdgeInsets(topBottom: 3, leftRight: 4)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 7
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(articleImageView)
        self.addSubview(articleTitleLabel)
        self.addSubview(articleBrandLabel)

        articleImageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(articleImageView.snp.height).dividedBy(0.8).priority(999)
            make.bottom.equalTo(articleTitleLabel.snp.top).inset(-4)
        }

        articleBrandLabel.snp.makeConstraints { make in
            make.right.equalTo(articleImageView).inset(5)
            make.bottom.equalTo(articleImageView).inset(5)
        }

        articleTitleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.height.equalTo(20).priority(999)
            make.bottom.equalTo(self)
        }
    }

    func render(article: Article) {
        articleImageView.render(images: article.thumbnail)  { (image, error, type, url) -> Void in
            if image == nil {
                self.articleImageView.render(named: "RIP-No-Image")
            }
        }
        articleTitleLabel.text = article.title
        articleBrandLabel.setTitle(article.brand, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}