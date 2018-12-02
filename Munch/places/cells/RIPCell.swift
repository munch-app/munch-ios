//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Crashlytics

class RIPCell: UITableViewCell {
    var data: PlaceData!
    var controller: RIPController!

    required init(data: PlaceData!, controller: RIPController) {
        super.init(style: .default, reuseIdentifier: nil)
        self.data = data
        self.controller = controller
        self.selectionStyle = .none

        self.didLoad(data: data)
        self.willDisplay(data: data)
    }

    /**
     * Might be called when PlaceData is nil
     */
    func didLoad(data: PlaceData!) {

    }

    /**
     * Might be called when PlaceData is nil
     */
    func willDisplay(data: PlaceData!) {

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

extension RIPCell {
    /**
     Create PlaceCardView from controller
     */
    class func create(controller: RIPController) -> RIPCell {
        return self.init(data: controller.data, controller: controller)
    }
}

class RIPSeparatorLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1.0 / UIScreen.main.scale))
        self.backgroundColor = UIColor(hex: "d5d4d8")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}