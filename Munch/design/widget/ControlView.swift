//
// Created by Fuxing Loh on 2019-02-18.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

open class ControlWidget: Widget {
    public let control = UIControl()

    public init(_ flutterView: Widget) {
        super.init(control)
        self.control.isUserInteractionEnabled = true

        self.view.addSubview(flutterView.view)
        flutterView.view.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view)
        }
    }

    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        self.control.addTarget(target, action: action, for: controlEvents)
    }
}