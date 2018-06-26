//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftRichString

class ReviewRatingUtils {
    static let min: (CGFloat, CGFloat, CGFloat) = (1.0, 0.0, 0.0)
    static let med: (CGFloat, CGFloat, CGFloat) = (0.90, 0.40, 0.0)
    static let max: (CGFloat, CGFloat, CGFloat) = (0.00, 0.77, 0.0)

    class func create(percent: CGFloat, fontSize: CGFloat = 14.0) -> NSAttributedString {
        let fixedPercent: CGFloat = percent > 1.0 ? 1.0 : percent

        return "\(Int(fixedPercent * 100))%".set(style: .default { make in
            make.font = FontAttribute(font: UIFont.systemFont(ofSize: fontSize, weight: .semibold))
            make.color = color(percent: fixedPercent)
        })
    }

    class func text(percent: CGFloat) -> String {
        let fixedPercent: CGFloat = percent > 1.0 ? 1.0 : percent
        return String(format: "%.1f", fixedPercent * 10)
    }

    class func width(percent: CGFloat, fontSize: CGFloat = 14.0) -> CGFloat {
        let string = create(percent: percent, fontSize: fontSize).string
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        return UILabel.textWidth(font: font, text: string)
    }

    class func color(percent: CGFloat) -> UIColor {
        let range = percent < 0.6 ? (min, med) : (med, max)
        let red = range.0.0 + (range.1.0 - range.0.0) * percent
        let green = range.0.1 + (range.1.1 - range.0.1) * percent
        let blue = range.0.2 + (range.1.2 - range.0.2) * percent

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

class ReviewRatingLabel: UIButton {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.setTitleColor(.white, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 11.0, weight: .semibold)

        self.contentEdgeInsets = UIEdgeInsets.init(top: 2, left: 6, bottom: 2, right: 6)
        self.layer.cornerRadius = 3.0
    }

    func render(average: Double) {
        let float = CGFloat(average)
        let color = ReviewRatingUtils.color(percent: float)
        let text = ReviewRatingUtils.text(percent: float)

        self.setTitle(text, for: .normal)
        self.backgroundColor = color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}