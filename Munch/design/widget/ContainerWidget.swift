//
// Created by Fuxing Loh on 2019-03-05.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

open class ContainerWidget: Widget {
    public init(_ flutterView: Widget? = nil) {
        super.init(UIView())

        if let view = flutterView?.view {
            self.view.addSubview(view)
        }
    }

    @discardableResult
    public func with(cornerRadius: CGFloat) -> ContainerWidget {
        self.view.layer.cornerRadius = cornerRadius
        return self
    }

    @discardableResult
    public func with(backgroundColor: UIColor) -> ContainerWidget {
        self.view.backgroundColor = backgroundColor
        return self
    }

    @discardableResult
    public func add(_ widget: Widget, _ closure: (_ make: ConstraintMaker) -> Void) -> ContainerWidget {
        self.view.addSubview(widget.view)
        widget.snp.makeConstraints(closure)
        return self
    }

    @discardableResult
    public func add(_ view: UIView, _ closure: (_ make: ConstraintMaker) -> Void) -> ContainerWidget {
        self.view.addSubview(view)
        view.snp.makeConstraints(closure)
        return self
    }
}