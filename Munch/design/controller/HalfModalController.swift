//
// Created by Fuxing Loh on 2018-12-07.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class HalfModalController: UIViewController, HalfModalPresentable {
    private let downButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "HalfModal-Down"), for: .normal)
        button.tintColor = .ba85
        button.imageEdgeInsets.right = 24
        button.imageEdgeInsets.left = 24
        button.imageEdgeInsets.top = 16
        button.imageEdgeInsets.bottom = 16
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .white
        self.view.shadow(vertical: -2)

        self.view.addSubview(downButton)

        downButton.addTarget(self, action: #selector(onDismiss(_:)), for: .touchUpInside)

        downButton.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeArea.top)
            maker.right.equalTo(self.view.safeArea.right)
            maker.width.equalTo(24 + 28 + 24)
            maker.height.equalTo(16 + 28 + 16)
        }
    }

    @objc func onDismiss(_ sender: Any) {
        self.dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}