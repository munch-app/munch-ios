//
//  Extensions.swift
//  Munch
//
//  Created by Fuxing Loh on 31/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

/**
 Hairline constraint is used to draw hairline divider
 */
class HairlineConstraint: NSLayoutConstraint {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.constant = 1.0 / UIScreen.main.scale
    }
}

class UIBorder {
    class var onePixel: CGFloat {
        get {
            return 1 / UIScreen.main.scale
        }
    }

    class var color: UIColor {
        get {
            return UIColor(hex: "C8C7CC")
        }
    }
}

extension UILabel {
    func textWidth() -> CGFloat {
        return UILabel.textWidth(label: self)
    }

    class func textWidth(label: UILabel) -> CGFloat {
        return textWidth(label: label, text: label.text!)
    }

    class func textWidth(label: UILabel, text: String) -> CGFloat {
        return textWidth(font: label.font, text: text)
    }

    class func textWidth(font: UIFont, text: String) -> CGFloat {
        let myText = text as NSString

        let rect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return ceil(labelSize.width)
    }
}

extension UIView {
    func hairlineShadow(width: CGFloat = -1.0, height: CGFloat = 1.0) {
        self.shadow(width: width, height: height, radius: 1.0, opacity: 0.52)
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
}

extension UIView {

    var safeArea: ConstraintBasicAttributesDSL {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        // TODO 20 top in the future
        let guide = UILayoutGuide()
        return guide.snp
    }

    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}

extension UIEdgeInsets {
    init(topBottom: CGFloat, leftRight: CGFloat) {
        self.init(top: topBottom, left: leftRight, bottom: topBottom, right: leftRight)
    }
}

@IBDesignable class HairlineShadowView: UIView {

    @IBInspectable var hairlineShadowHeight: CGFloat = 0 {
        didSet {
            if (hairlineShadowHeight != 0) {
                hairlineShadow(height: hairlineShadowHeight)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if (hairlineShadowHeight != 0) {
            hairlineShadow(height: hairlineShadowHeight)
        }
    }
}

extension Array {

    // Safely lookup an index that might be out of bounds,
    // returning nil if it does not exist
    func get(_ index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
}

extension UIViewController {

    func alert(error: Error) {
        alert(title: "Unhandled Error", message: error.localizedDescription)
    }

    func alert(title: String, error: Error) {
        alert(title: title, message: error.localizedDescription)
    }

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true)
    }
}

extension UINavigationController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}


// For supporting development in school

extension UITabBarController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
