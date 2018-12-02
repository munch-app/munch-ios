//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class MunchSearchTextField: UITextField {
    private let leftImagePadding: CGFloat = 6
    private let leftImageSize: CGFloat = 18

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.layer.cornerRadius = 4
        self.backgroundColor = .whisper100

        self.font = UIFont.systemFont(ofSize: 16, weight: .regular)

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "SC-Search-18")
        imageView.tintColor = .black

        self.leftViewMode = .always
        self.leftView = imageView

        self.placeholder = "Try \"Chinese\""

        self.returnKeyType = .search
        self.autocorrectionType = .no
        self.clearButtonMode = .whileEditing
        self.autocapitalizationType = .none
    }

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.origin.x += leftImagePadding
        rect.size.width = leftImageSize + (leftImagePadding * 2)
        return rect
    }

    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: UIColor.ba85])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
