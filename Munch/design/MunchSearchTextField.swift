//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SwiftRichString

class MunchSearchTextField: UITextField {
    private static let leftImagePadding: CGFloat = 8
    private static let leftImageSize: CGFloat = 18

    private let leftImageView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
        view.contentMode = .scaleAspectFit
        view.tintColor = .black
        return view
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .whisper100
        self.layer.cornerRadius = 4

        self.leftViewMode = .always
        self.leftView = self.leftImageView
        self.set(icon: .glass)

        self.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        self.returnKeyType = .search
        self.autocorrectionType = .no
        self.clearButtonMode = .whileEditing
        self.autocapitalizationType = .none
    }

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.origin.x += MunchSearchTextField.leftImagePadding
        rect.size.width = MunchSearchTextField.leftImageSize + (MunchSearchTextField.leftImagePadding * 2)
        return rect
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MunchSearchTextField {
    static let period = "  •  ".set(style: Style {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .ultraLight)
        $0.color = UIColor.ba75
    })

    enum Icon: String {
        case glass = "Search-Header-Glass"
        case back = "Search-Header-Back"
    }

    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: UIColor.ba75])
        }
    }

    func set(icon: Icon) {
        self.leftImageView.image = UIImage(named: icon.rawValue)
    }

    func set(tokens: [FilterToken]) {
        let attributed = NSMutableAttributedString()


        if let first = tokens.get(0)?.text {
            attributed.append(first.set(style: Style {
                $0.color = UIColor.black
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }))
        }
        if let second = tokens.get(1)?.text {
            attributed.append(MunchSearchTextField.period)
            attributed.append(second.set(style: Style {
                $0.color = UIColor.black
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }))
        }

        let count = tokens.count - 2
        if count > 0 {
            attributed.append(MunchSearchTextField.period)
            attributed.append("+\(count)".set(style: Style {
                $0.color = UIColor.black
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }))
        }

        attributedPlaceholder = attributed
    }
}