//
//  ShimmerView.swift
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

class ShimmerView: FBShimmeringView {
    init(color: UIColor = .whisper100) {
        super.init(frame: .zero)
        self.contentView = UIView()
        self.contentView.backgroundColor = color

        self.isShimmering = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
