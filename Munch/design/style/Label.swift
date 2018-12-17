//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

enum FontStyle {
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6

    case navHeader
    case large
    case regular
    case subtext
    case small
    case smallBold

    func height(text: String, width: CGFloat) -> CGFloat {
        return UILabel.textHeight(withWidth: width, font: self.font, text: text)
    }

    func width(text: String) -> CGFloat {
        return UILabel.textWidth(font: self.font, text: text)
    }

    func size(text: String, extra: CGSize = .zero) -> CGSize {
        return UILabel.textSize(font: self.font, text: text, extra: extra)
    }

    var font: UIFont {
        switch self {
        case .h1:
            return UIFont.systemFont(ofSize: 32, weight: .semibold)
        case .h2:
            return UIFont.systemFont(ofSize: 23, weight: .semibold)
        case .h3:
            return UIFont.systemFont(ofSize: 21, weight: .semibold)
        case .h4:
            return UIFont.systemFont(ofSize: 19, weight: .semibold)
        case .h5:
            return UIFont.systemFont(ofSize: 17, weight: .semibold)
        case .h6:
            return UIFont.systemFont(ofSize: 15, weight: .semibold)

        case .navHeader:
            return UIFont.systemFont(ofSize: 16, weight: .semibold)

        case .large:
            return UIFont.systemFont(ofSize: 19, weight: .regular)
        case .regular:
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        case .subtext:
            return UIFont.systemFont(ofSize: 14, weight: .regular)
        case .small:
            return UIFont.systemFont(ofSize: 12, weight: .regular)
        case .smallBold:
            return UIFont.systemFont(ofSize: 12, weight: .semibold)
        }
    }

    var color: UIColor {
        switch self {
        case .h1: fallthrough
        case .h2: fallthrough
        case .h3: fallthrough
        case .h4: fallthrough
        case .h5: fallthrough
        case .h6:
            return .ba75

        case .large: fallthrough
        case .regular: fallthrough
        case .small: fallthrough
        case .smallBold:
            return .black

        case .subtext: fallthrough
        case .navHeader:
            return .ba85
        }
    }
}

extension UILabel {
    convenience init(style: FontStyle) {
        self.init()
        self.with(style: style)
    }

    convenience init(size: CGFloat, weight: UIFont.Weight, color: UIColor) {
        self.init()
        self.with(size: size, weight: weight, color: color)
    }

    func with(text: String) -> UILabel {
        self.text = text
        return self
    }

    @discardableResult
    func with(text: String?, lineSpacing: CGFloat) -> UILabel {
        self.text = text
        
        if let text = text {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing

            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
            self.attributedText = attributedString    
        }
        return self
    }

    func with(numberOfLines: Int) -> UILabel {
        self.numberOfLines = numberOfLines
        return self
    }

    func with(alignment: NSTextAlignment) -> UILabel {
        self.textAlignment = alignment
        return self
    }

    func with(color: UIColor) -> UILabel {
        self.textColor = color
        return self
    }

    func with(size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        return with(font: UIFont.systemFont(ofSize: size, weight: weight))
                .with(color: color)
    }

    func with(font: UIFont) -> UILabel {
        self.font = font
        return self
    }

    func with(style: FontStyle) -> UILabel {
        return with(font: style.font)
                .with(color: style.color)
    }

    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        guard let labelText = self.text else {
            return
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

        let attributedString: NSMutableAttributedString
        if let labelAttributeText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributeText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))


        self.attributedText = attributedString
    }
}