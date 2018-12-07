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
    let scrollView = UIScrollView()

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
        self.headerView.render()

        if Authentication.isAuthenticated() {
            self.headerView.render()
        } else {
            self.tabBarController?.selectedIndex = 0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(scrollView)
        self.view.addSubview(headerView)
        self.addTargets()

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        // TODO: Remove Temp Delegate
        scrollView.delegate = self
        let view = UIView()
        view.backgroundColor = .peach100
        scrollView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.left.right.equalTo(self.view)
            maker.height.equalTo(10000).priority(999)
            maker.top.equalTo(self.scrollView)
            maker.bottom.equalTo(self.scrollView)
        }
    }
}

// MARK: Add Targets
extension ProfileController {
    func addTargets() {
        self.headerView.settingButton.addTarget(self, action: #selector(onActionSetting(_:)), for: .touchUpInside)

        for tabButton in self.headerView.tabButtons {
            tabButton.addTarget(self, action: #selector(onTab(selected:)), for: .touchUpInside)
        }
    }

    @objc func onActionSetting(_ sender: Any) {
        let controller = ProfileSettingController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc fileprivate func onTab(selected: ProfileTabButton) {
        // TODO
    }
}

// MARK: Scroll Delegate
extension ProfileController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.headerView.contentDidScroll(scrollView: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            scrollViewDidFinish(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidFinish(scrollView)
    }

    func scrollViewDidFinish(_ scrollView: UIScrollView) {
        // Check nearest locate and move to it
        if let y = self.headerView.contentShouldMove(scrollView: scrollView) {
            let point = CGPoint(x: 0, y: y)
            scrollView.setContentOffset(point, animated: true)
        }
    }
}