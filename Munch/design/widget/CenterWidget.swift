//
// Created by Fuxing Loh on 2019-02-21.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

open class CenterWidget: Widget {
    public init(_ flutterView: Widget) {
        super.init(UIView())

        self.view.addSubview(flutterView.view)
        flutterView.view.snp.makeConstraints { maker in
            maker.center.equalTo(self.view)
        }
    }
}