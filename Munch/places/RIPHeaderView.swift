//
// Created by Fuxing Loh on 2018-12-05.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPHeaderView: UIView {
    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()
    let moreBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "RIP-Header-More"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.right = 18
        button.contentHorizontalAlignment = .right
        return button
    }()
    let titleView: UILabel = {
        let titleView = UILabel(style: .navHeader)
        return titleView
    }()

    let backgroundView = UIView()
    let shadowView = UIView()

    var place: Place? {
        didSet {
            if let place = place {
                self.titleView.text = place.name
            } else {
                self.titleView.text = nil
            }
        }
    }
    override var tintColor: UIColor! {
        didSet {
            self.backButton.tintColor = tintColor
            self.moreBtn.tintColor = tintColor
            self.titleView.textColor = tintColor
        }
    }

    init(tintColor: UIColor = .black, backgroundVisible: Bool = true, titleHidden: Bool = false) {
        super.init(frame: CGRect.zero)
        self.initViews()

        self.titleView.isHidden = titleHidden
        self.tintColor = tintColor

        self.backgroundView.backgroundColor = .white
        self.backgroundView.isHidden = !backgroundVisible
        self.shadowView.isHidden = !backgroundVisible
    }

    private func initViews() {
        self.backgroundColor = .clear
        self.backgroundView.backgroundColor = .clear

        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)
        self.addSubview(titleView)
        self.addSubview(moreBtn)

        backButton.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.left.bottom.equalTo(self)

            maker.width.equalTo(52)
            maker.height.equalTo(44)
        }

        moreBtn.snp.makeConstraints { maker in
            maker.right.equalTo(self)
            maker.top.bottom.equalTo(backButton)
            maker.width.equalTo(56)
        }

        titleView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self.backButton)
            maker.left.equalTo(backButton.snp.right)
            maker.right.equalTo(moreBtn.snp.left).inset(-16)
        }

        backgroundView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}