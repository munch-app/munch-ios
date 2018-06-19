//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class ProfileRootController: UINavigationController, UINavigationControllerDelegate {
    let profileController = ProfileController()

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [profileController]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileController: UIViewController {

}