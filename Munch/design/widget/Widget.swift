//
// Created by Fuxing Loh on 2019-02-18.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

open class Widget {
    public let view: UIView

    public init(_ view: UIView) {
        self.view = view
        self.view.isUserInteractionEnabled = false
    }

    var isHidden: Bool {
        get {
            return self.view.isHidden
        }
        set(value) {
            self.view.isHidden = value
        }
    }
    // BuildContext
    // View hierarchy
}

extension Widget {
    public var snp: ConstraintViewDSL {
        return self.view.snp
    }

    public func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        self.view.snp.makeConstraints(closure)
    }
}

extension UIView {
    func addSubview(_ view: Widget) {
        self.addSubview(view.view)
    }
}