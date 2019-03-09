//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ContentLine: UITableViewCell {
    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let container = ContainerWidget()
        self.addSubview(container) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self).inset(12)
            maker.centerX.equalTo(self)
        }

        let d1 = ContentLineDot()
        let d2 = ContentLineDot()
        let d3 = ContentLineDot()
        let d4 = ContentLineDot()
        container.add(d1) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(container)
        }
        container.add(d2) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(d1.snp.right)
        }
        container.add(d3) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(d2.snp.right)
        }
        container.add(d4) { (maker: ConstraintMaker) -> Void in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(d3.snp.right)
            maker.right.equalTo(container)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContentLineDot: PaddingWidget {
    init() {
        super.init(insets: UIEdgeInsets(all: 8), view: ContainerWidget()
                .with(height: 6)
                .with(width: 6)
                .with(backgroundColor: .ba50)
                .with(cornerRadius: 3)
        )
    }
}