//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Crashlytics

class RIPCard: UICollectionViewCell {
    var controller: RIPController!

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    func register(data: PlaceData!, controller: RIPController) {
        if self.controller == nil {
            self.controller = controller
            self.didLoad(data: data)
        }
    }

    /**
     * didLoad & willDisplay separated for better convention
     * Might be called when PlaceData is nil for card loaded before start
     */
    func didLoad(data: PlaceData!) {

    }

    /**
     * didLoad & willDisplay separated for better convention
     */
    func willDisplay(data: PlaceData!) {

    }

    /**
     * Card did selected
     */
    func didSelect(data: PlaceData!, controller: RIPController) {

    }

    /**
     * Whether the data required for this cell is available
     */
    class func isAvailable(data: PlaceData) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RIPSeparatorLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1.0 / UIScreen.main.scale))
        self.backgroundColor = .ba10

        snp.makeConstraints { maker in
            maker.height.equalTo(1.0 / UIScreen.main.scale).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}