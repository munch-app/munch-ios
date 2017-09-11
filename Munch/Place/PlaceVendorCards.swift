//
//  PlaceVendorCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class VendorArticleGridCard: UITableViewCell, PlaceCardView {
    let titleLabel = UILabel()
    let seeMoreBtn = UIButton()
    let articleView1 = ArticleGridView()
    let articleView2 = ArticleGridView()
    let articleView3 = ArticleGridView()
    let articleView4 = ArticleGridView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        titleLabel.text = "Articles"
        titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: UIFontWeightMedium)
        super.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: PlaceCard) {
        // Hide See More if < 4
        // Hide Articles if not shown
    }
    
    static var id: String {
        return "vendor_ArticleGrid_10092017"
    }
    
    class ArticleGridView: UIView {
        let brandLabel = UILabel()
        let imageView = UILabel()
        let descriptionLabel = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func hide() {
            
        }
    }
}
