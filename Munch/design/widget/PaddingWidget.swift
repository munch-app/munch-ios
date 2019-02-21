//
// Created by Fuxing Loh on 2019-02-14.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

// Convenience padding view
open class PaddingWidget: Widget {
    convenience init(h: CGFloat = 0, v: CGFloat = 0, view: UIView) {
        self.init(top: v, bottom: v, left: h, right: h, view: view)
    }

    convenience init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0, view: UIView) {
        self.init(insets: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right), view: Widget(view))
    }

    convenience init(all: CGFloat = 0, view: UIView) {
        self.init(insets: UIEdgeInsets(top: all, left: all, bottom: all, right: all), view: Widget(view))
    }

    convenience init(h: CGFloat = 0, v: CGFloat = 0, view: Widget) {
        self.init(insets: UIEdgeInsets(top: v, left: h, bottom: v, right: h), view: view)
    }

    convenience init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0, view: Widget) {
        self.init(insets: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right), view: view)
    }

    convenience init(all: CGFloat = 0, view: Widget) {
        self.init(insets: UIEdgeInsets(top: all, left: all, bottom: all, right: all), view: view)
    }

    public init(insets: UIEdgeInsets, view flutterView: Widget) {
        super.init(UIView())

        self.view.addSubview(flutterView.view)
        flutterView.view.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view).inset(insets)
        }
    }
}