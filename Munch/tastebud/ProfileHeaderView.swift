//
// Created by Fuxing Loh on 2018-12-07.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

enum ProfileHeaderTab {
    case places
    case preferences

    var name: String {
        switch self {
        case .places:
            return "Places"

        case .preferences:
            return "Preferences"
        }
    }
}

class ProfileTabButton: UIControl {
    private let nameLabel: UILabel = {
        let nameLabel = UILabel(style: .navHeader)
        .with(font: UIFont.systemFont(ofSize: 17, weight: .semibold))
        nameLabel.textAlignment = .left
        return nameLabel
    }()
    private let indicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        return view
    }()

    let tab: ProfileHeaderTab

    init(tab: ProfileHeaderTab) {
        self.tab = tab
        self.nameLabel.text = tab.name
        super.init(frame: .zero)

        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        self.addSubview(indicator)
        indicator.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.height.equalTo(2)
            maker.bottom.equalTo(self).inset(8)
        }

        self.isSelected = false
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.nameLabel.with(color: UIColor.black)
                self.indicator.isHidden = false
            } else {
                self.nameLabel.with(color: UIColor.black.withAlphaComponent(0.7))
                self.indicator.isHidden = true
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileHeaderView: UIView {
    let munchIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "Tastebud-Munch-Logo")
        return view
    }()

    let placeBtn = ProfileTabButton(tab: .places)
    let preferenceBtn = ProfileTabButton(tab: .preferences)

    let settingBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Setting"), for: .normal)
        button.tintColor = .black
        button.contentHorizontalAlignment = .right
        button.imageEdgeInsets.right = 24
        return button
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(munchIcon)
        self.addSubview(placeBtn)
        self.addSubview(preferenceBtn)
        self.addSubview(settingBtn)

        settingBtn.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)
            maker.right.equalTo(self)
            maker.width.equalTo(64)
            maker.height.equalTo(44)
        }

        munchIcon.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(settingBtn)
            maker.left.equalTo(self).inset(24)
        }

        placeBtn.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(settingBtn)
            maker.left.equalTo(munchIcon.snp.right).inset(-24)
        }

        preferenceBtn.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(settingBtn)
            maker.left.equalTo(placeBtn.snp.right).inset(-24)
        }

        placeBtn.isSelected = true
        placeBtn.addTarget(self, action: #selector(onTab(_:)), for: .touchUpInside)
        preferenceBtn.addTarget(self, action: #selector(onTab(_:)), for: .touchUpInside)
    }

    @objc func onTab(_ sender: ProfileTabButton) {
        if sender === self.placeBtn {
            placeBtn.isSelected = true
            preferenceBtn.isSelected = false
        } else if sender === self.preferenceBtn {
            preferenceBtn.isSelected = true
            placeBtn.isSelected = false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}