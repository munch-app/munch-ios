//
//  PlaceVendorCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class PlaceVendorArticleGridCard: PlaceCardView {
    let titleLabel = UILabel()
    
    let topRow = ArticleGridRowView()
    let bottomRow = ArticleGridRowView()
    
    override func didLoad(card: PlaceCard) {
        super.addSubview(titleLabel)
        titleLabel.text = "Articles"
        titleLabel.font = UIFont.systemFont(ofSize: 21.0, weight: UIFont.Weight.medium)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }
        
        // Hide See More if < 4
        // Hide Articles if not shown
        let articles = card["articles"].map { Article(json: $0.1) }
        super.addSubview(topRow)
        topRow.left.render(article: articles.get(0))
        topRow.right.render(article: articles.get(1))
        topRow.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-6)
        }
        
        if (articles.count > 1) {
            super.addSubview(bottomRow)
            bottomRow.left.render(article: articles.get(2))
            bottomRow.right.render(article: articles.get(3))
            bottomRow.snp.makeConstraints { (make) in
                make.left.right.equalTo(self).inset(leftRight)
                make.top.equalTo(topRow.snp.bottom)
                make.bottom.equalTo(self)
            }
        } else {
            topRow.snp.makeConstraints({ (make) in
                make.bottom.equalTo(self)
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
                make.top.bottom.equalTo(self).inset(5)
                make.left.equalTo(self)
                make.right.equalTo(right.snp.left).inset(12)
                make.width.equalTo(right.snp.width)
            }
            
            right.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(self).inset(5)
                make.right.equalTo(self)
                make.left.equalTo(left.snp.right).inset(12)
                make.width.equalTo(left.snp.width)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class ArticleGridView: UIView {
        let imageView = ShimmerImageView()
        let titleLabel = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            titleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
            self.addSubview(imageView)
            self.addSubview(titleLabel)
            
            imageView.snp.makeConstraints { (make) in
                make.height.equalTo(imageView.snp.width)
                make.left.right.equalTo(self)
                make.top.equalTo(self)
            }
            
            titleLabel.numberOfLines = 2
            titleLabel.snp.makeConstraints { (make) in
                make.left.right.equalTo(self)
                make.top.equalTo(imageView.snp.bottom).inset(-6)
                make.bottom.equalTo(self)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(article: Article?) {
            if let article = article {
                imageView.render(imageMeta: article.thumbnail)
                titleLabel.text = article.title
            } else {
                self.isHidden = true
            }
        }
    }
}
