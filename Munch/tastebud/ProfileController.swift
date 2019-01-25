//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

import Localize_Swift
import NVActivityIndicatorView

class ProfileRootController: UINavigationController, UINavigationControllerDelegate {
    let controller = ProfileController()

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [controller]
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
    let headerView = ProfileHeaderView()
    let containment = UIView()

    let savedPlaceController = ProfileSavedPlaceController()
    let preferenceController = ProfilePreferenceController()
    var currentController: UIViewController?

    let disposeBag = DisposeBag()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !Authentication.isAuthenticated() {
            self.tabBarController?.selectedIndex = 0
            return
        }

        MunchAnalytic.setScreen("/profile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(containment)
        self.view.addSubview(headerView)
        self.addTargets()

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        containment.snp.makeConstraints { maker in
            maker.left.right.equalTo(self.view)
            maker.top.equalTo(headerView.snp.bottom)
            maker.bottom.equalTo(self.view)
        }

        self.replace(replacing: savedPlaceController)
    }
}

// MARK: Add Targets
extension ProfileController {
    func addTargets() {
        self.headerView.settingBtn.addTarget(self, action: #selector(onActionSetting(_:)), for: .touchUpInside)

        self.headerView.placeBtn.addTarget(self, action: #selector(onTab(selected:)), for: .touchUpInside)
        self.headerView.preferenceBtn.addTarget(self, action: #selector(onTab(selected:)), for: .touchUpInside)
    }

    @objc func onActionSetting(_ sender: Any) {
        let controller = ProfileSettingController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc fileprivate func onTab(selected: ProfileTabButton) {
        switch selected.tab {
        case .places:
            replace(replacing: savedPlaceController)

        case .preferences:
            replace(replacing: preferenceController)
        }
    }

    func replace(replacing: UIViewController) {
        if let currentController = currentController {
            if currentController == replacing {
                return
            }

            currentController.willMove(toParentViewController: nil)
            currentController.view.removeFromSuperview()
            currentController.removeFromParentViewController()
        }


        self.addChildViewController(replacing)
        self.containment.addSubview(replacing.view)
        replacing.view.snp.makeConstraints { maker in
            maker.edges.equalTo(self.containment)
        }
        replacing.didMove(toParentViewController: parent)
    }
}