//
// Created by Fuxing Loh on 19/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SafariServices

class RIPSuggestEditCard: RIPCard {
    private let separatorLine = RIPSeparatorLine()
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Suggest Edits", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = FontStyle.regular.font
        button.isUserInteractionEnabled = false

        button.setImage(UIImage(named: "RIP-Card-Edit"), for: .normal)
        button.tintColor = UIColor.black
        button.imageEdgeInsets.right = 18
        return button
    }()

    override func didLoad(data: PlaceData!) {
        self.addSubview(button)
        self.addSubview(separatorLine)
        self.addTargets(controller: self.controller)

        button.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self).inset(12)
        }

        separatorLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(button.snp.bottom).inset(-24)
            maker.bottom.equalTo(self).inset(12)
        }
    }
}

extension RIPSuggestEditCard: SFSafariViewControllerDelegate {
    func addTargets(controller: RIPController) {
        self.button.addTarget(self, action: #selector(onSuggestEdit), for: .touchUpInside)
    }

    func onSuggestEdit() {
        Authentication.requireAuthentication(controller: self.controller) { state in
            switch state {
            case .loggedIn:
                // TODO Open With Token
                break
            default:
                return
            }
        }

    }
}