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

    case large
    case regular
    case subtext
    case small
    case smallBold

    var font: UIFont {
        switch self {
        case .h1:
            return UIFont.systemFont(ofSize: 32, weight: .medium)
        case .h2:
            return UIFont.systemFont(ofSize: 24, weight: .medium)
        case .h3:
            return UIFont.systemFont(ofSize: 20, weight: .medium)
        case .h4:
            return UIFont.systemFont(ofSize: 18, weight: .medium)
        case .h5:
            return UIFont.systemFont(ofSize: 16, weight: .medium)
        case .h6:
            return UIFont.systemFont(ofSize: 14, weight: .medium)

        case .large:
            return UIFont.systemFont(ofSize: 19, weight: .regular)
        case .regular:
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        case .subtext:
            return UIFont.systemFont(ofSize: 14, weight: .medium)
        case .small:
            return UIFont.systemFont(ofSize: 12, weight: .regular)
        case .smallBold:
            return UIFont.systemFont(ofSize: 12, weight: .medium)
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

        case .subtext:
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
}