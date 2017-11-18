//
//  Shimmer.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Shimmer
import SwiftyJSON

class ShimmerImageView: UIView {
    let shimmerView = ShimmerView()
    let imageView = MunchImageView()
    
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.addSubview(shimmerView)
        self.addSubview(imageView)

        shimmerView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
        // Override default image setting
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(images: JSON?) {
        render(images: images?.dictionaryObject as? [String: String])
    }
    
    func render(placeImage: Place.Image?) {
        render(images: placeImage?.images)
    }
    
    func render(images: [String: String]?) {
        self.imageView.isHidden = true
        self.shimmerView.isHidden = false
        self.shimmerView.isShimmering = true
        imageView.render(images: images) { _, error, _, _ in
            if (error == nil) {
                self.imageView.isHidden = false
                self.shimmerView.isHidden = true
                self.shimmerView.isShimmering = false
            }
        }
    }
}

class ShimmerView: FBShimmeringView {
    
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.contentView = UIView()
        self.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        self.isShimmering = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
