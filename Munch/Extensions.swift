//
//  Extensions.swift
//  Munch
//
//  Created by Fuxing Loh on 31/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

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
            return 1/UIScreen.main.scale
        }
    }

    class var color: UIColor {
        get {
            return UIColor(hex: "C8C7CC")
        }
    }
}

extension UIScreen {
    class var width: CGFloat {
        get {
            return main.bounds.width
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
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return ceil(labelSize.width)
    }
}

extension UIView {
    func hairlineShadow(height: CGFloat = 1.0) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.26).cgColor
        self.layer.shadowOpacity = 0.52
        self.layer.shadowOffset = CGSize(width: -1, height: height)
        self.layer.shadowRadius = 1
        
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        
        self.layer.rasterizationScale = UIScreen.main.scale
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

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
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
        let alert = UIAlertController(title: "Unhandled Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true)
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true)
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
