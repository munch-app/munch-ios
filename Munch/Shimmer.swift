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

struct ShimmerIndicator: Indicator {
    let shimmerView = ShimmerView()
    let view: UIView = UIView()

    func startAnimatingView() {
        self.view.isHidden = false
    }

    func stopAnimatingView() {
        self.view.isHidden = true
    }

    init() {
        view.addSubview(shimmerView)
        shimmerView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
}

class ShimmerImageView: MunchImageView {
    private let indicator = ShimmerIndicator()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.kf.indicatorType = .custom(indicator: indicator)

        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ScaledHeightShimmerImageView: MunchImageView {
    private let indicator = ShimmerIndicator()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.kf.indicatorType = .custom(indicator: indicator)

        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        if let myImage = self.image {
            let myImageWidth = myImage.size.width
            let myImageHeight = myImage.size.height
            let myViewWidth = self.frame.size.width

            let ratio = myViewWidth/myImageWidth
            let scaledHeight = myImageHeight * ratio

            return CGSize(width: myViewWidth, height: scaledHeight)
        }

        return self.bounds.size
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
