//
// Created by Fuxing Loh on 2018-12-02.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString
import Localize_Swift

import BEMCheckBox

class FilterItemCellTagHeader: UITableViewCell {
    private let label = UILabel(style: .h1)
            .with(numberOfLines: 1)

    var type: Tag.TagType! {
        didSet {
            label.text = self.type.text
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.top.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(8)
            maker.left.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FilterItemCellTagMore: UITableViewCell {
    private let titleLabel = UILabel(size: 17, weight: .medium, color: .secondary500)
    var type: Tag.TagType? {
        didSet {
            titleLabel.text = "Show All \(self.type!.text)"
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(10)
            maker.left.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FilterItemCellTag: UITableViewCell {
    private let nameLabel = UILabel(size: 16, weight: .regular, color: .black)
    private let countLabel = UILabel(size: 16, weight: .medium, color: .black)

    private let checkBox: BEMCheckBox = {
        let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        checkButton.boxType = .square
        checkButton.lineWidth = 2
        checkButton.cornerRadius = 1
        checkButton.tintColor = UIColor(hex: "444444")
        checkButton.animationDuration = 0.25
        checkButton.isEnabled = false

        checkButton.onCheckColor = .white
        checkButton.onTintColor = .primary500
        checkButton.onFillColor = .primary500
        return checkButton
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(nameLabel)
        self.addSubview(countLabel)
        self.addSubview(checkBox)

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self).inset(12)
            make.left.equalTo(self).inset(24)

            make.right.equalTo(checkBox.snp.left).inset(-16)
        }

        checkBox.snp.makeConstraints { make in
            make.top.bottom.equalTo(nameLabel)
            make.right.equalTo(self).inset(24)
        }

        countLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(nameLabel)
            make.right.equalTo(checkBox.snp.left).inset(-16)
        }
    }

    func render(name: String, count: Int?, selected: Bool) {
        if let count = count {
            if count > 0 {
                countLabel.text = FilterManager.countTitle(count: count, prefix: "", postfix: "")
            } else {
                countLabel.text = "0"
            }
        }

        nameLabel.text = name
        checkBox.setOn(selected, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}