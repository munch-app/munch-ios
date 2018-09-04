//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Toast_Swift

import SnapKit
import Moya

extension UIViewController {

    func alert(error: Error) {
        print(error)
        if let error = error as? MoyaError {
            alert(error: error)
        } else {
            alert(title: "Unhandled Error", message: error.localizedDescription)
        }
    }

    func alert(title: String, error: Error) {
        print(error)
        alert(title: title, message: error.localizedDescription)
    }

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true)
    }
}

let DefaultToastStyle: Toast_Swift.ToastStyle = {
    var style = ToastStyle()
    style.backgroundColor = UIColor.bgTag
    style.cornerRadius = 5
    style.imageSize = CGSize(width: 20, height: 20)
    style.fadeDuration = 6.0
    style.messageColor = UIColor.black.withAlphaComponent(0.85)
    style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    style.messageNumberOfLines = 2
    style.messageAlignment = .left

    return style
}()

extension UIViewController {
    enum ToastImage {
        case named(String)
        case checkmark
        case close

        var image: UIImage? {
            switch self {
            case .checkmark:
                return UIImage(named: "RIP-Toast-Checkmark")
            case .close:
                return UIImage(named: "RIP-Toast-Close")
            case .named(let name):
                return UIImage(named: name)
            }
        }
    }


    func makeToast(_ text: String, image: ToastImage) {
        self.view.makeToast(text, image: image.image, style: DefaultToastStyle)
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

extension UICollectionViewLayoutAttributes {
    func leftAlignFrameWithSectionInset(_ sectionInset: UIEdgeInsets) {
        var frame = self.frame
        frame.origin.x = sectionInset.left
        self.frame = frame
    }
}

extension UIView {
    var safeArea: ConstraintBasicAttributesDSL {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        let guide = UILayoutGuide()
        return guide.snp
    }
}

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

extension UIEdgeInsets {
    init(topBottom: CGFloat, leftRight: CGFloat) {
        self.init(top: topBottom, left: leftRight, bottom: topBottom, right: leftRight)
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
        return textSize(font: font, text: text).width
    }

    class func textHeight(withWidth width: CGFloat, font: UIFont, text: String) -> CGFloat {
        return textSize(font: font, text: text, width: width).height
    }

    class func textSize(font: UIFont, text: String, extra: CGSize) -> CGSize {
        var size = textSize(font: font, text: text)
        size.width = size.width + extra.width
        size.height = size.height + extra.height
        return size
    }

    class func textSize(font: UIFont, text: String, width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        label.numberOfLines = 0
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.size
    }

    class func countLines(font: UIFont, text: String, width: CGFloat, height: CGFloat = .greatestFiniteMagnitude) -> Int {
        // Call self.layoutIfNeeded() if your view uses auto layout
        let myText = text as NSString

        let rect = CGSize(width: width, height: height)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)

        return Int(ceil(CGFloat(labelSize.height) / font.lineHeight))
    }

    func countLines(width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> Int {
        let myText = (self.text ?? "") as NSString

        let rect = CGSize(width: width, height: height)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.font], context: nil)

        return Int(ceil(CGFloat(labelSize.height) / self.font.lineHeight))
    }
}