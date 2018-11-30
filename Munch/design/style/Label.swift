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
}

extension UILabel {
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

    func with(font: UIFont) -> UILabel {
        self.font = font
        return self
    }

    func with(size: CGFloat, weight: Int, color: UIColor) -> UILabel {
        switch weight {
        case 300:
            self.font = UIFont.systemFont(ofSize: size, weight: .light)
        case 400:
            self.font = UIFont.systemFont(ofSize: size, weight: .regular)
        case 600:
            self.font = UIFont.systemFont(ofSize: size, weight: .medium)
        case 700:
            self.font = UIFont.systemFont(ofSize: size, weight: .semibold)
        case 800:
            self.font = UIFont.systemFont(ofSize: size, weight: .bold)
        default:
            self.font = UIFont.systemFont(ofSize: size, weight: .regular)
        }

        return with(color: color)
    }

    func with(style: FontStyle) -> UILabel {
        switch style {
        case .h1:
            return with(size: 32, weight: 600, color: .ba75)
        case .h2:
            return with(size: 24, weight: 600, color: .ba75)
        case .h3:
            return with(size: 20, weight: 600, color: .ba75)
        case .h4:
            return with(size: 18, weight: 600, color: .ba75)
        case .h5:
            return with(size: 16, weight: 600, color: .ba75)
        case .h6:
            return with(size: 14, weight: 600, color: .ba75)

        case .large:
            return with(size: 19, weight: 400, color: .black)
        case .regular:
            return with(size: 16, weight: 600, color: .black)
        case .subtext:
            return with(size: 14, weight: 400, color: .ba85)
        case .small:
            return with(size: 12, weight: 400, color: .black)
        case .smallBold:
            return with(size: 12, weight: 600, color: .black)
        }
    }
}