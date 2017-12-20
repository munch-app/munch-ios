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
        self.title = "Article"
    }

    override class var cardId: String? {
        return "header_Article_20171112"
    }
}

class PlaceVendorArticleGridCard: PlaceCardView {
    let topRow = RowView()
    let bottomRow = RowView()

    override func didLoad(card: PlaceCard) {
        // Hide See More if < 4
        // Hide Articles if not shown
        let articles = card.data.map({ Article(json: $0.1) })
        super.addSubview(topRow)

        topRow.render(left: articles.get(0), right: articles.get(1), controller: controller)
        topRow.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom).priority(999)
        }

        if (articles.count > 3) {
            super.addSubview(bottomRow)

            bottomRow.render(left: articles.get(2), right: articles.get(3), controller: controller)
            bottomRow.snp.makeConstraints { (make) in
                make.left.right.equalTo(self).inset(leftRight)
                make.top.equalTo(topRow.snp.bottom).inset(-15).priority(999)
                make.bottom.equalTo(self).inset(topBottom).priority(999)
            }
        } else {
            topRow.snp.makeConstraints({ (make) in
                make.bottom.equalTo(self).inset(topBottom).priority(999)
            })
        }
    }

    override class var cardId: String? {
        return "vendor_Article_20171029"
    }

    class RowView: UIView {
        let leftView = ArticleView()
        let rightView = ArticleView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(leftView)
            self.addSubview(rightView)

            leftView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(self).priority(999)
                make.right.equalTo(rightView.snp.left).inset(-20).priority(999)
                make.left.equalTo(self).priority(999)
                make.width.equalTo(rightView.snp.width).priority(999)
            }

            rightView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(self).priority(999)
                make.left.equalTo(leftView.snp.right).inset(-20).priority(999)
                make.right.equalTo(self).priority(999)
                make.width.equalTo(leftView.snp.width).priority(999)
            }
        }

        func render(left: Article?, right: Article?, controller: PlaceViewController) {
            leftView.render(article: left, controller: controller)
            rightView.render(article: right, controller: controller)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class ArticleView: UIView, SFSafariViewControllerDelegate {
        let articleImageView = ShimmerImageView()
        let articleTitleLabel = UILabel()

        var article: Article!
        var controller: PlaceViewController!

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(articleImageView)
            self.addSubview(articleTitleLabel)

            articleImageView.layer.cornerRadius = 2
            articleImageView.snp.makeConstraints { (make) in
                make.left.right.equalTo(self)
                make.top.equalTo(self)
                make.width.equalTo(articleImageView.snp.height).dividedBy(0.8).priority(999)
                make.bottom.equalTo(articleTitleLabel.snp.top).inset(-8)
            }

            articleTitleLabel.numberOfLines = 2
            articleTitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            articleTitleLabel.snp.makeConstraints { (make) in
                make.left.right.equalTo(self)
                make.height.equalTo(30).priority(999)
                make.bottom.equalTo(self)
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            self.addGestureRecognizer(tap)
            self.isUserInteractionEnabled = true
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(article: Article?, controller: PlaceViewController) {
            self.article = article
            self.controller = controller

            if let article = article {
                articleImageView.render(images: article.thumbnail)
                articleTitleLabel.text = article.title
            } else {
                self.isHidden = true
            }
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            if let articleUrl = article.url, let url = URL(string: articleUrl) {
                let safari = SFSafariViewController(url: url)
                safari.delegate = self
                controller.present(safari, animated: true, completion: nil)
            }
        }
    }
}
