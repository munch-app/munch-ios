//
//  PlaceShimmerCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Shimmer

class RIPLoadingImageCell: RIPCell {
    override func didLoad(data: PlaceData!) {
        let shimmerView = FBShimmeringView()
        let colorView = UIView()
        colorView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        shimmerView.contentView = colorView
        shimmerView.isShimmering = true
        self.addSubview(shimmerView)

        shimmerView.snp.makeConstraints { make in
            make.height.equalTo(260)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0))
        }
    }
}

class RIPLoadingNameCell: RIPCell {
    override func didLoad(data: PlaceData!) {
        let shimmerView = FBShimmeringView()
        let colorView = UIView()
        colorView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        shimmerView.contentView = colorView
        shimmerView.isShimmering = true
        self.addSubview(shimmerView)

        shimmerView.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.edges.equalTo(self).inset(UIEdgeInsets(topBottom: 12, leftRight: 24))
        }
    }
}