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
        let myText = text as NSString

        let rect = CGSize(width: width, height: height)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return labelSize.size
    }

    class func countLines(font: UIFont, text: String, width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> Int {
        // Call self.layoutIfNeeded() if your view uses auto layout
        let myText = text as NSString

        let rect = CGSize(width: width, height: height)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)

        return Int(ceil(CGFloat(labelSize.height) / font.lineHeight))
    }

    func countLines(width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> Int {
        // Call self.layoutIfNeeded() if your view uses auto layout
        let myText = (self.text ?? "") as NSString

        let rect = CGSize(width: width, height: height)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.font], context: nil)

        return Int(ceil(CGFloat(labelSize.height) / self.font.lineHeight))
    }
}

class SRCopyableLabel: UILabel {

    override public var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
                target: self,
                action: #selector(showMenu(sender:))
        ))
    }

    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    @objc func showMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(copy(_:)))
    }
}

class SRCopyableView: UIView {

    override public var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
                target: self,
                action: #selector(showMenu(sender:))
        ))
    }

    var copyableText: String? {
        return ""
    }

    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = self.copyableText
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    @objc func showMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(copy(_:)))
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

extension UIView {
    var safeArea: ConstraintBasicAttributesDSL {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        let guide = UILayoutGuide()
        return guide.snp
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

extension UICollectionViewLayoutAttributes {
    func leftAlignFrameWithSectionInset(_ sectionInset: UIEdgeInsets) {
        var frame = self.frame
        frame.origin.x = sectionInset.left
        self.frame = frame
    }
}

class UICollectionViewLeftAlignedLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var attributesCopy: [UICollectionViewLayoutAttributes] = []
        if let attributes = super.layoutAttributesForElements(in: rect) {
            attributes.forEach({ attributesCopy.append($0.copy() as! UICollectionViewLayoutAttributes) })
        }

        for attributes in attributesCopy {
            if attributes.representedElementKind == nil {
                let indexpath = attributes.indexPath
                if let attr = layoutAttributesForItem(at: indexpath) {
                    attributes.frame = attr.frame
                }
            }
        }
        return attributesCopy
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        if let currentItemAttributes = super.layoutAttributesForItem(at: indexPath as IndexPath)?.copy() as? UICollectionViewLayoutAttributes {
            let sectionInset = self.evaluatedSectionInsetForItem(at: indexPath.section)
            let isFirstItemInSection = indexPath.item == 0
            let layoutWidth = self.collectionView!.frame.width - sectionInset.left - sectionInset.right

            if (isFirstItemInSection) {
                currentItemAttributes.leftAlignFrameWithSectionInset(sectionInset)
                return currentItemAttributes
            }

            let previousIndexPath = IndexPath.init(row: indexPath.item - 1, section: indexPath.section)

            let previousFrame = layoutAttributesForItem(at: previousIndexPath)?.frame ?? CGRect.zero
            let previousFrameRightPoint = previousFrame.origin.x + previousFrame.width
            let currentFrame = currentItemAttributes.frame
            let stretchedCurrentFrame = CGRect.init(x: sectionInset.left,
                    y: currentFrame.origin.y,
                    width: layoutWidth,
                    height: currentFrame.size.height)
            // if the current frame, once left aligned to the left and stretched to the full collection view
            // width intersects the previous frame then they are on the same line
            let isFirstItemInRow = !previousFrame.intersects(stretchedCurrentFrame)

            if (isFirstItemInRow) {
                // make sure the first item on a line is left aligned
                currentItemAttributes.leftAlignFrameWithSectionInset(sectionInset)
                return currentItemAttributes
            }

            var frame = currentItemAttributes.frame
            frame.origin.x = previousFrameRightPoint + evaluatedMinimumInteritemSpacing(at: indexPath.section)
            currentItemAttributes.frame = frame
            return currentItemAttributes

        }
        return nil
    }

    func evaluatedMinimumInteritemSpacing(at sectionIndex: Int) -> CGFloat {
        if let delegate = self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout {
            let inteitemSpacing = delegate.collectionView?(self.collectionView!, layout: self, minimumInteritemSpacingForSectionAt: sectionIndex)
            if let inteitemSpacing = inteitemSpacing {
                return inteitemSpacing
            }
        }
        return self.minimumInteritemSpacing

    }

    func evaluatedSectionInsetForItem(at index: Int) -> UIEdgeInsets {
        if let delegate = self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout {
            let insetForSection = delegate.collectionView?(self.collectionView!, layout: self, insetForSectionAt: index)
            if let insetForSectionAt = insetForSection {
                return insetForSectionAt
            }
        }
        return self.sectionInset
    }
}