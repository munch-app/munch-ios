//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import NVActivityIndicatorView

class ContentLoading: UITableViewCell {
    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none


        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        let indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .secondary500, padding: 0)
        indicator.startAnimating()

        self.addSubview(indicator) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self)
            maker.height.equalTo(40)
            maker.top.bottom.equalTo(self).inset(48)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}