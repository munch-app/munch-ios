//
// Created by Fuxing Loh on 2018-12-05.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPBottomView: UIView {
    let saveBtn = RIPSaveButton()

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
            maker.top.equalTo(self).inset(10)
            maker.bottom.equalTo(self.safeArea.bottom).inset(10)
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

class RIPSaveButton: UIButton {
    private let nameLabel = UILabel()
            .with(alignment: .center)
            .with(numberOfLines: 1)
            .with(text: "Save Place")

    required init() {
        super.init(frame: .zero)
        self.addSubview(nameLabel)

        self.backgroundColor = .secondary500
        self.nameLabel.textColor = .white
        self.nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)

        snp.makeConstraints { maker in
            maker.height.equalTo(36)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self)
            maker.left.right.equalTo(self).inset(18)
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