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
    func addSubview(_ widget: Widget) {
        self.addSubview(widget.view)
    }

    func addSubview(_ widget: Widget, _ closure: (_ make: ConstraintMaker) -> Void) {
        self.addSubview(widget.view)
        widget.snp.makeConstraints(closure)
    }

    func addSubview(_ view: UIView, _ closure: (_ make: ConstraintMaker) -> Void) {
        self.addSubview(view)
        view.snp.makeConstraints(closure)
    }
}

extension ConstraintMakerRelatable {

    @discardableResult
    public func equalTo(_ other: Widget, _ file: String = #file, _ line: UInt = #line) -> ConstraintMakerEditable {
        return self.equalTo(other.view, file, line)
    }

}