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
import Kingfisher

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

    func render(named: String) {
        self.imageView.image = UIImage(named: named)
    }

    func render(images: JSON?, completionHandler: CompletionHandler? = nil) {
        render(images: images?.dictionaryObject as? [String: String], completionHandler: completionHandler)
    }
    
    func render(sourcedImage: SourcedImage?, completionHandler: CompletionHandler? = nil) {
        render(images: sourcedImage?.images, completionHandler: completionHandler)
    }
    
    func render(images: [String: String]?, completionHandler: CompletionHandler? = nil) {
        self.imageView.isHidden = true
        self.shimmerView.isHidden = false
        self.shimmerView.isShimmering = true
        imageView.render(images: images) { image, error, cacheType, imageUrl in
            if (error == nil) {
                self.imageView.isHidden = false
                self.shimmerView.isHidden = true
                self.shimmerView.isShimmering = false
            }
            completionHandler?(image, error, cacheType, imageUrl)
        }
    }
}

class ShimmerView: FBShimmeringView {
    
    init(frame: CGRect = CGRect(), color: UIColor = UIColor.black.withAlphaComponent(0.1)) {
        super.init(frame: frame)
        self.contentView = UIView()
        self.contentView.backgroundColor = color
        
        self.isShimmering = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
