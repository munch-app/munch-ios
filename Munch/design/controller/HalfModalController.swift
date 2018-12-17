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

class HalfModalTextController: HalfModalController {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()
    private let headerLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)
    private let textLabel = UILabel(style: .regular)
            .with(numberOfLines: 0)

    init(header: String?, text: String) {
        headerLabel.text = header
        textLabel.with(text: text, lineSpacing: 1.5)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.addSubview(headerLabel)
        scrollView.addSubview(textLabel)
        self.view.addSubview(scrollView)

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeArea.top)
            maker.bottom.equalTo(self.view.safeArea.bottom)
            maker.left.right.equalTo(self.view)
        }

        headerLabel.snp.makeConstraints { maker in
            maker.top.equalTo(scrollView).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }

        textLabel.snp.makeConstraints { maker in
            maker.top.equalTo(headerLabel.snp.bottom).inset(-16)
            maker.bottom.equalTo(scrollView).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}