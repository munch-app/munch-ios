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

    var title: String {
        switch self {
        case .places:
            return "Your Places"

        case .preferences:
            return "Preferences"
        }
    }

    var icon: String {
        return ""
    }
}

class ProfileHeaderView: UIView {

    let settingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Setting"), for: .normal)
        button.tintColor = .black
        button.contentHorizontalAlignment = .right
        button.imageEdgeInsets.right = 24
        return button
    }()

    let nameLabel = UILabel(style: .navHeader)
            .with(numberOfLines: 1)

//    let tabButtons = [
//        ProfileTabButton(type: .places),
//        ProfileTabButton(type: .preferences),
//    ]
//    fileprivate var selectedType: ProfileHeaderTab {
//        for button in tabButtons {
//            if button.isSelected {
//                return button.type
//            }
//        }
//        return ProfileHeaderTab.places
//    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(nameLabel)
        self.addSubview(settingButton)
//        tabButtons.forEach({ self.addSubview($0) })

        settingButton.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)
            maker.right.equalTo(self)
            maker.width.equalTo(64)
            maker.height.equalTo(44)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(settingButton)
            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(settingButton.snp.left).inset(-16)
        }

//        tabButtons[0].isSelected = true
//        for tab in tabButtons {
//            tab.addTarget(self, action: #selector(onSelectTab(selected:)), for: .touchUpInside)
//        }
    }

    func update() {
        let profile = UserProfile.instance
        self.nameLabel.text = profile?.name
    }

//    @objc fileprivate func onSelectTab(selected: ProfileTabButton) {
//        for tabButton in tabButtons {
//            if tabButton == selected {
//                tabButton.isSelected = true
//            } else {
//                tabButton.isSelected = false
//            }
//        }
//    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileTabButton: UIButton {
//    private let nameLabel: UILabel = {
//        let nameLabel = UILabel()
//        nameLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
//        nameLabel.textColor = .ba75
//
//        nameLabel.numberOfLines = 1
//        nameLabel.isUserInteractionEnabled = false
//        nameLabel.textAlignment = .left
//        return nameLabel
//    }()
//    private let indicatorView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .primary500
//        return view
//    }()
//
//    let type: ProfileHeaderTab
//
//    init(type: ProfileHeaderTab) {
//        self.type = type
//        super.init(frame: .zero)
//
//        self.addSubview(nameLabel)
//        self.addSubview(indicatorView)
//
//        nameLabel.text = type.title
//        nameLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.top.equalTo(self).inset(13)
//        }
//
//        indicatorView.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.bottom.equalTo(self)
//            make.height.equalTo(2)
//        }
//    }
//
//    override var isSelected: Bool {
//        get {
//            return !self.indicatorView.isHidden
//        }
//
//        set(value) {
//            self.indicatorView.isHidden = !value
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}