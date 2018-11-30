//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Localize_Swift

import Moya
import RxSwift
import RxCocoa

class HomeRootController: UINavigationController, UINavigationControllerDelegate {
    let controller = HomeController()

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

class HomeController: UIViewController {
    let headerView = HomeHeaderView()
    let searchTableView = SearchTableView(screen: .home)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        if AccountRootBoardingController.toShow {
            self.present(AccountRootBoardingController(guestOption: true, withCompletion: { state in
            }), animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(searchTableView)
        self.view.addSubview(headerView)

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        searchTableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp_bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        self.searchTableView.cardDelegate = self
        self.searchTableView.search(screen: .home)
    }
}


extension HomeController: SearchTableViewDelegate {
    func searchTableView(didSelectCardAt card: SearchCard) {

    }

    func searchTableView(requireController: @escaping (UIViewController) -> Void) {
        requireController(self)
    }
}

class HomeHeaderView: UIView {
    let logoView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Home_MunchLogo")
        return imageView
    }()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.addSubview(logoView)
        self.backgroundColor = .white

        logoView.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top)
            maker.bottom.equalTo(self)

            maker.height.equalTo(44)
            maker.centerX.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}