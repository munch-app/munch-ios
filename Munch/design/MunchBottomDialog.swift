//
// Created by Fuxing Loh on 2019-02-26.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import MaterialComponents.MaterialBottomSheet

typealias MunchBottomDialogClosure = () -> ()

extension UIViewController {

    func show(title: String, message: String, buttonTitle: String? = nil, buttonCallback: MunchBottomDialogClosure? = nil) {
        let controller = MunchBottomDialogController(title: title, message: message, buttonTitle: buttonTitle, buttonCallback: buttonCallback)
        self.show(bottomSheet: controller)
    }

    func show(bottomSheet: MunchBottomDialogController) {
        let controller = MDCBottomSheetController(contentViewController: bottomSheet)
        self.present(controller, animated: true)
    }
}

class MunchBottomDialogController: UIViewController {
    let messageTitle: String
    let messageBody: String
    let buttonTitle: String?
    let buttonCallback: MunchBottomDialogClosure?

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
    private let bgControl = UIControl()
    private let container = UIView()

    required init(title: String, message: String, buttonTitle: String?, buttonCallback: MunchBottomDialogClosure?) {
        self.messageTitle = title
        self.messageBody = message
        self.buttonTitle = buttonTitle
        self.buttonCallback = buttonCallback
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(bgControl)
        self.view.addSubview(container)
        self.view.addSubview(downButton)

        downButton.addTarget(self, action: #selector(onEnd), for: .touchUpInside)
        downButton.snp.makeConstraints { maker in
            maker.top.equalTo(self.container)
            maker.right.equalTo(self.container)
            maker.width.equalTo(24 + 28 + 24)
            maker.height.equalTo(16 + 28 + 16)
        }

        container.backgroundColor = .white
        container.snp.makeConstraints { maker in
            maker.left.right.equalTo(self.view)
            maker.bottom.equalTo(self.view)
        }

        bgControl.addTarget(self, action: #selector(onEnd), for: .touchUpInside)
        bgControl.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view)
        }

        let titleWidget = UILabel(style: .h4).with(text: messageTitle)
        container.addSubview(titleWidget)

        titleWidget.snp.makeConstraints { maker in
            maker.top.left.equalTo(self.container).inset(24)
            maker.right.equalTo(self.downButton.snp.left)
        }

        let bodyWidget = UILabel(style: .regular).with(text: messageBody).with(numberOfLines: 0)
        container.addSubview(bodyWidget)
        bodyWidget.snp.makeConstraints { maker in
            maker.top.equalTo(titleWidget.snp.bottom).inset(-16)
            maker.left.right.equalTo(self.container).inset(24)

            if buttonTitle == nil {
                maker.bottom.equalTo(self.view.safeArea.bottom).inset(24)
            }
        }

        if let buttonTitle = buttonTitle {
            let button = MunchButton(style: .secondary).with(text: buttonTitle)
            button.addTarget(self, action: #selector(onButton), for: .touchUpInside)

            container.addSubview(button)
            button.snp.makeConstraints { maker in
                maker.top.equalTo(bodyWidget.snp.bottom).inset(-24)
                maker.right.equalTo(self.container).inset(24)
                maker.bottom.equalTo(self.view.safeArea.bottom).inset(24)
            }
        }
    }

    @objc func onEnd() {
        self.dismiss(animated: true)
    }

    @objc func onButton() {
        self.dismiss(animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
            self.buttonCallback?()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}