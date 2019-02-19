//
// Created by Fuxing Loh on 2019-02-18.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

typealias UIControlTargetClosure = (UIControl) -> ()

class ClosureWrapper: NSObject {
    let closure: UIControlTargetClosure

    init(_ closure: @escaping UIControlTargetClosure) {
        self.closure = closure
    }
}

extension UIControl {
    fileprivate struct AssociatedKeys {
        static var touchUpInsideClosure = "targetClosure"
    }

    fileprivate var touchUpInsideClosure: UIControlTargetClosure? {
        get {
            guard let closureWrapper = objc_getAssociatedObject(self, &AssociatedKeys.touchUpInsideClosure) as? ClosureWrapper else {
                return nil
            }
            return closureWrapper.closure
        }
        set(newValue) {
            guard let newValue = newValue else {
                return
            }
            objc_setAssociatedObject(self, &AssociatedKeys.touchUpInsideClosure, ClosureWrapper(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func onTouchUpInside(_ closure: @escaping UIControlTargetClosure) {
        touchUpInsideClosure = closure
        addTarget(self, action: #selector(touchClosureAction), for: .touchUpInside)
    }

    @objc
    fileprivate func touchClosureAction() {
        guard let touchUpInsideClosure = touchUpInsideClosure else {
            return
        }
        touchUpInsideClosure(self)
    }
}