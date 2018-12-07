//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

enum MunchButtonStyle {
    case border
    case borderSmall
    case primary
    case primarySmall
    case secondary
    case secondarySmall
}

extension MunchButtonStyle {
    var padding: CGFloat {
        switch self {
        case .borderSmall: fallthrough
        case .primarySmall: fallthrough
        case .secondarySmall:
            return 18

        default:
            return 24
        }
    }

    var height: CGFloat {
        switch self {
        case .borderSmall: fallthrough
        case .primarySmall: fallthrough
        case .secondarySmall:
            return 36

        default:
            return 40
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .border: fallthrough
        case .borderSmall:
            return 1

        default:
            return 0
        }
    }

    var background: UIColor {
        switch self {
        case .border: fallthrough
        case .borderSmall:
            return UIColor(hex: "FCFCFC")

        case .primary: fallthrough
        case .primarySmall:
            return .primary500

        case .secondary: fallthrough
        case .secondarySmall:
            return .secondary500
        }
    }

    var color: UIColor {
        switch self {
        case .border: fallthrough
        case .borderSmall:
            return .black

        default:
            return .white
        }
    }

    var font: UIFont {
        switch self {
        case .borderSmall: fallthrough
        case .primarySmall: fallthrough
        case .secondarySmall:
            return UIFont.systemFont(ofSize: 15, weight: .bold)

        default:
            return UIFont.systemFont(ofSize: 16, weight: .bold)
        }
    }
}

class MunchButton: UIButton {
    private let nameLabel = UILabel()
            .with(alignment: .center)
            .with(numberOfLines: 1)

    required init(style: MunchButtonStyle) {
        super.init(frame: .zero)
        self.addSubview(nameLabel)

        self.backgroundColor = style.background
        self.layer.borderWidth = style.borderWidth
        self.layer.borderColor = UIColor.ba15.cgColor
        self.nameLabel.textColor = style.color
        self.nameLabel.font = style.font

        snp.makeConstraints { maker in
            maker.height.equalTo(style.height).priority(.high)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self)
            maker.left.right.equalTo(self).inset(style.padding)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 3.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MunchButton {
    func with(text: String?) -> MunchButton {
        self.nameLabel.text = text
        return self
    }
}