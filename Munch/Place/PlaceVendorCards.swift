//
//  PlaceVendorCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import Cosmos

class PlaceVendorArticleGridCard: PlaceCardView {
    let titleLabel = UILabel()
    
    let topRow = ArticleGridRowView()
    let bottomRow = ArticleGridRowView()
    
    override func didLoad(card: PlaceCard) {
        super.addSubview(titleLabel)
        titleLabel.text = "Articles"
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.medium)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }
        
        // Hide See More if < 4
        // Hide Articles if not shown
        let articles = card["articles"].map { Article(json: $0.1) }
        super.addSubview(topRow)
        topRow.left.render(article: articles.get(0), controller: controller)
        topRow.right.render(article: articles.get(1), controller: controller)
        topRow.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-10)
        }
        
        if (articles.count > 2) {
            super.addSubview(bottomRow)
            bottomRow.left.render(article: articles.get(2), controller: controller)
            bottomRow.right.render(article: articles.get(3), controller: controller)
            bottomRow.snp.makeConstraints { (make) in
                make.left.right.equalTo(self).inset(leftRight)
                make.top.equalTo(topRow.snp.bottom).inset(-15)
                make.bottom.equalTo(self).inset(topBottom)
            }
        } else {
            topRow.snp.makeConstraints({ (make) in
                make.bottom.equalTo(self).inset(topBottom)
            })
        }
    }
    
    override class var cardId: String? {
        return "vendor_ArticleGrid_10092017"
    }

    class ArticleGridRowView: UIView {
        let left = ArticleGridView()
        let right = ArticleGridView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(left)
            self.addSubview(right)
            
            left.snp.makeConstraints { (make) in
                make.right.equalTo(right.snp.left).inset(-15)
                make.top.bottom.equalTo(self)
                make.left.equalTo(self)
                make.width.equalTo(right.snp.width)
            }
            
            right.snp.makeConstraints { (make) in
                make.left.equalTo(left.snp.right).inset(-15)
                make.top.bottom.equalTo(self)
                make.right.equalTo(self)
                make.width.equalTo(left.snp.width)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class ArticleGridView: UIView, SFSafariViewControllerDelegate {
        let articleImageView = ShimmerImageView()
        let articleTitleLabel = UILabel()
        
        var article: Article!
        var controller: PlaceViewController!
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            articleTitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
            self.addSubview(articleImageView)
            self.addSubview(articleTitleLabel)
            
            articleImageView.snp.makeConstraints { (make) in
                make.height.equalTo(articleImageView.snp.width)
                make.left.right.equalTo(self)
                make.top.equalTo(self)
            }
            
            articleTitleLabel.numberOfLines = 2
            articleTitleLabel.snp.makeConstraints { (make) in
                make.left.right.equalTo(self)
                make.top.equalTo(articleImageView.snp.bottom).inset(-6)
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

class PlaceHeaderReviewCard: PlaceCardView {
    let titleLabel = UILabel()
    
    override func didLoad(card: PlaceCard) {
        self.addSubview(titleLabel)
        titleLabel.text = "Reviews"
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.medium)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
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
        self.addSubview(titleLabel)
        self.addSubview(ratingView)
        self.addSubview(countLabel)
        
        titleLabel.text = "Facebook"
        titleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(self)
        }
        
        ratingView.rating = card["overallStarRating"].double ?? 5
        ratingView.settings.fillMode = .precise
        ratingView.settings.filledColor = UIColor.init(hex: "#3B5998")
        ratingView.settings.filledBorderColor = UIColor.init(hex: "#3B5998")
        ratingView.settings.emptyBorderColor = UIColor.clear
        ratingView.settings.emptyBorderColor = UIColor.init(hex: "#3B5998")
        ratingView.settings.starSize = 18
        ratingView.settings.starMargin = 0
        ratingView.snp.makeConstraints { (make) in
            make.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self)
        }
        
        countLabel.text = "Based on \(card["ratingCount"].int ?? 0) reviews"
        countLabel.font = UIFont.systemFont(ofSize: 11.0, weight: UIFont.Weight.regular)
        countLabel.textAlignment = .center
        countLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(leftRight)
            make.top.equalTo(ratingView.snp.bottom).inset(-5)
            make.bottom.equalToSuperview().inset(topBottom)
        }
        
        if let facebookPlaceId = card["placeId"].string {
            self.facebookReviewUrl = URL.init(string: "https://www.facebook.com/\(facebookPlaceId)/reviews")
        }
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
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
