//
// Created by Fuxing Loh on 2019-02-18.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

// Convenience padding view
open class IconWidget: Widget {
    let imageView = UIImageView()

    public init(size: CGFloat, image: UIImage? = nil, tintColor: UIColor = .black) {
        super.init(imageView)
        self.imageView.image = image
        self.imageView.tintColor = tintColor
        self.imageView.contentMode = .scaleAspectFit

        self.imageView.snp.makeConstraints { maker in
            maker.height.width.equalTo(size)
        }
    }

    open var image: UIImage?  {
        set(value) {
            self.imageView.image = value
        }
        get {
            return self.imageView.image
        }
    }
}
