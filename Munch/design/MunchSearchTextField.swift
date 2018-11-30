//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class MunchSearchTextField: UITextField {

    let leftImagePadding: CGFloat = 3
    let leftImageWidth: CGFloat = 32
    let leftImageSize: CGFloat = 18

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.layer.cornerRadius = 4
        self.backgroundColor = .whisper100

        self.font = UIFont.systemFont(ofSize: 15, weight: .regular)


        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "SC-Search-18")
        imageView.tintColor = .ba85

        self.leftViewMode = .always
        self.leftView = imageView

        placeholder = "Search e.g. Italian in Marina Bay".localized()
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ? placeholder! : "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.ba85])
    }

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftImagePadding
        textRect.size.width = leftImageWidth
        return textRect
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
