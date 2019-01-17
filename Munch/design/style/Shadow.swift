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

// // In css it's structure as such
//// none|h-offset v-offset blur spread color
//
//const elevation1 = [
//  BoxShadow(
//      offset: Offset(0, 1),
//      blurRadius: 1,
//      color: Color.fromRGBO(0, 0, 0, 0.12)),
//  BoxShadow(
//      offset: Offset(0, 1),
//      blurRadius: 2,
//      color: Color.fromRGBO(0, 0, 0, 0.24)),
//];
//
//const elevation2 = [
//  BoxShadow(
//      offset: Offset(0, 3),
//      blurRadius: 6,
//      color: Color.fromRGBO(0, 0, 0, 0.16)),
//  BoxShadow(
//      offset: Offset(0, 3),
//      blurRadius: 6,
//      color: Color.fromRGBO(0, 0, 0, 0.23)),
//];
//
//const elevation3 = [
//  BoxShadow(
//      offset: Offset(0, 10),
//      blurRadius: 20,
//      color: Color.fromRGBO(0, 0, 0, 0.19)),
//  BoxShadow(
//      offset: Offset(0, 6),
//      blurRadius: 6,
//      color: Color.fromRGBO(0, 0, 0, 0.23)),
//];
//
//const elevation4 = [
//  BoxShadow(
//      offset: Offset(0, 14),
//      blurRadius: 28,
//      color: Color.fromRGBO(0, 0, 0, 0.25)),
//  BoxShadow(
//      offset: Offset(0, 10),
//      blurRadius: 10,
//      color: Color.fromRGBO(0, 0, 0, 0.22)),
//];
//
//const elevation5 = [
//  BoxShadow(
//      offset: Offset(0, 19),
//      blurRadius: 38,
//      color: Color.fromRGBO(0, 0, 0, 0.30)),
//  BoxShadow(
//      offset: Offset(0, 15),
//      blurRadius: 12,
//      color: Color.fromRGBO(0, 0, 0, 0.22)),
//];