//
//  Shimmer.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Shimmer

class ShimmerImageView: FBShimmeringView {
    let imageView = UIImageView()
    
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.contentView = imageView
        
        // Override default image setting
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(placeImage: Place.Image?) {
        render(imageMeta: placeImage?.imageMeta)
    }
    
    func render(imageMeta: ImageMeta?) {
        self.isShimmering = true
        imageView.render(imageMeta: imageMeta) { _, error, _, _ in
            if (error == nil) {
                self.isShimmering = false
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
