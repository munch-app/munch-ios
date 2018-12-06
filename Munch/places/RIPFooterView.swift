//
// Created by Fuxing Loh on 2018-12-05.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPBottomView: UIView {
    let saveBtn: MunchButton = {
        let btn = MunchButton(style: .secondary)
        btn.with(text: "Save Place")
        return btn
    }()

    var place: Place? {
        didSet {
            if let place = place {
                self.setHidden(isHidden: false)
            } else {
                self.setHidden(isHidden: true)
            }
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.setHidden(isHidden: true)

        self.addSubview(saveBtn)

        saveBtn.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
            maker.bottom.equalTo(self.safeArea.bottom).inset(12)
        }
    }

    private func setHidden(isHidden: Bool) {
        saveBtn.isHidden = isHidden
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
