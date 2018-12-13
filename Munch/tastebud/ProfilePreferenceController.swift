//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ProfilePreferenceController: UIViewController {
    let button = MunchButton(style: .secondary).with(text: "Preference")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        self.view.addSubview(button)

        button.snp.makeConstraints { maker in
            maker.center.equalTo(self.view)
        }
    }
}