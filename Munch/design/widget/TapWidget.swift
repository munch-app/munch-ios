//
// Created by Fuxing Loh on 2019-02-18.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

open class TapWidget: Widget {
    public let recognizer: UITapGestureRecognizer

    public init(_ widget: Widget, recognizer: UITapGestureRecognizer) {
        self.recognizer = recognizer
        super.init(widget.view)
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(recognizer)
    }
}