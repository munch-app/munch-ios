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
            return "PLACES"

        case .preferences:
            return "PREFERENCES"
        }
    }
}

class ProfileHeaderView: UIView {
    let fold1: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }() // Image & Setting
    let fold0: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }() // Profile Details
    let fold2: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }() // Tab Bar
    fileprivate var topConstraint: Constraint! = nil

    let settingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Setting"), for: .normal)
        button.tintColor = .black
        button.contentHorizontalAlignment = .right
        button.imageEdgeInsets.right = 24
        return button
    }()

    let profileImageView: SizeImageView = {
        let imageView = SizeImageView(points: 22, height: 22)
        imageView.layer.cornerRadius = 22

        imageView.backgroundColor = .whisper100
        imageView.clipsToBounds = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.numberOfLines = 1
        return label
    }()

    let tabButtons = [
        ProfileTabButton(type: .places)
    ]
    fileprivate var selectedType: ProfileHeaderTab {
        for button in tabButtons {
            if button.isSelected {
                return button.type
            }
        }
        return ProfileHeaderTab.places
    }

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()

        tabButtons[0].isSelected = true
        for tab in tabButtons {
            tab.addTarget(self, action: #selector(onSelectTab(selected:)), for: .touchUpInside)
        }
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(fold0)
        self.addSubview(fold1)
        self.addSubview(fold2)

        // Middle
        fold0.addSubview(nameLabel)

        fold1.addSubview(profileImageView)
        fold1.addSubview(settingButton)
        fold1.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self)

            settingButton.snp.makeConstraints { maker in
                maker.top.equalTo(self.safeArea.top)
                maker.right.bottom.equalTo(fold1)

                maker.width.equalTo(64)
            }

            profileImageView.snp.makeConstraints { maker in
                maker.left.equalTo(fold1).inset(24)

                maker.top.equalTo(self.safeArea.top)
                maker.bottom.equalTo(fold1)
                maker.height.width.equalTo(foldHeights[0])
            }
        }

        fold0.snp.makeConstraints { make in
            self.topConstraint = make.top.equalTo(fold1.snp.bottom).constraint
            make.left.right.equalTo(self)
            make.height.equalTo(foldHeights[1])

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(fold0).inset(24)
                make.top.equalTo(fold0).inset(12)
            }
        }

        tabButtons.forEach({ fold2.addSubview($0) })
        fold2.snp.makeConstraints { make in
            make.top.equalTo(fold0.snp.bottom)
            make.bottom.left.right.equalTo(self)
            make.height.equalTo(foldHeights[2])
        }

        // Setup Profile Tabs
        var leftOfTab: UIView? = nil
        for tab in tabButtons {
            tab.snp.makeConstraints { make in
                make.top.bottom.equalTo(fold2)
                if let left = leftOfTab {
                    make.left.equalTo(left).inset(-24)
                } else {
                    make.left.equalTo(fold2).inset(24)
                }
                leftOfTab = tab
            }
        }
    }

    func render() {
        let profile = UserProfile.instance
        self.profileImageView.render(url: profile?.photoUrl)
        self.nameLabel.text = profile?.name
    }

    @objc fileprivate func onSelectTab(selected: ProfileTabButton) {
        for tabButton in tabButtons {
            if tabButton == selected {
                tabButton.isSelected = true
            } else {
                tabButton.isSelected = false
            }
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

extension ProfileHeaderView {
    private var foldHeights: [CGFloat] {
        return [44, 35, 40]
    }

    var contentHeight: CGFloat {
        return 44 + 35 + 40
    }

    var maxHeight: CGFloat {
        // contentHeight + safeArea.top
        return self.safeAreaInsets.top + contentHeight
    }

    func contentDidScroll(scrollView: UIScrollView) {
        let offset = calculateOffset(scrollView: scrollView)
        self.topConstraint.update(inset: offset)
    }

    /**
     nil means don't move
     */
    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
        let offset = calculateOffset(scrollView: scrollView)

        // Already fully closed or opened
        if (offset == foldHeights[1] || offset == 0.0) {
            return nil
        }

        if (offset < foldHeights[1] / 2) {
            // To close
            return -maxHeight + foldHeights[1]
        } else {
            // To open
            return -maxHeight
        }
    }

    private func calculateOffset(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y

        if y <= -maxHeight {
            return 0
        } else if y >= -maxHeight + foldHeights[1] {
            return foldHeights[1]
        } else {
            return (maxHeight + y)
        }
    }
}

class ProfileTabButton: UIButton {
    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .bold)
        nameLabel.textColor = .ba75

        nameLabel.numberOfLines = 1
        nameLabel.isUserInteractionEnabled = false
        nameLabel.textAlignment = .left
        return nameLabel
    }()
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .primary500
        return view
    }()

    let type: ProfileHeaderTab

    init(type: ProfileHeaderTab) {
        self.type = type
        super.init(frame: .zero)

        self.addSubview(nameLabel)
        self.addSubview(indicatorView)

        nameLabel.text = type.title
        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(13)
        }

        indicatorView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(2)
        }
    }

    override var isSelected: Bool {
        get {
            return !self.indicatorView.isHidden
        }

        set(value) {
            self.indicatorView.isHidden = !value
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}