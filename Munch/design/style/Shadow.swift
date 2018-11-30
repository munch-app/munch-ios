//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func hairlineShadow(width: CGFloat = -1.0, height: CGFloat = 1.0) {
        self.shadow(width: width, height: height, radius: 1.0, opacity: 0.52)
    }

    func shadow(vertical height: CGFloat = 1.0) {
        self.shadow(width: 0, height: height, radius: abs(height), opacity: 0.6, color: UIColor.black.withAlphaComponent(0.25))
    }

    func shadow(horizontal width: CGFloat = 1.0) {
        self.shadow(width: width, height: 0, radius: abs(width), opacity: 0.6, color: UIColor.black.withAlphaComponent(0.25))
    }

    func shadow(width: CGFloat, height: CGFloat, radius: CGFloat, opacity: Float, color: UIColor = UIColor.black.withAlphaComponent(0.26)) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = CGSize(width: width, height: height)
        self.layer.shadowRadius = radius

        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true

        self.layer.rasterizationScale = UIScreen.main.scale
    }

    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        // self.layer.cornerRadius = 3, if all corner same radius
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}