//
//  TabBarController.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import ESTabBarController_swift


/**
 Initial view provider
 */
enum InitialViewProvider {

    /**
     Main tab controllers for Munch App
     */
    static func main() -> TabBarController {
        return TabBarController()
    }

    fileprivate static func search() -> UIViewController {
        let controller = SearchNavigationalController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "Discover", image: UIImage(named: "TabBar-Search"))
        return controller
    }

    fileprivate static func account() -> UIViewController {
        let controller = AccountController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "Profile", image: UIImage(named: "TabBar-Profile"))
        return controller
    }
}

class TabBarController: ESTabBarController, UITabBarControllerDelegate {
    var previousController: UIViewController?
    var sameTabCounter = 0

    let searchController = InitialViewProvider.search()
    let accountController = InitialViewProvider.account()

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.shadow(vertical: -1.0)
        tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: -10)

        self.delegate = self
        self.viewControllers = [searchController, accountController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if (viewController is AccountController) {
            if AccountAuthentication.isAuthenticated() {
                return true
            }

            AccountAuthentication.requireAuthentication(controller: self) { state in
                switch state {
                case .loggedIn:
                    tabBarController.selectedViewController = self.accountController
                default:
                    return
                }
            }
        }

        if let navigation = viewController as? UINavigationController {
            if let controller = navigation.topViewController as? SearchController {
                if (self.previousController == viewController) {
                    sameTabCounter += 1
                    if (sameTabCounter >= 2) {
                        controller.scrollsToTop(animated: true)
                    }
                } else {
                    sameTabCounter = 0
                }
                self.previousController = viewController
            }
        }

        return true
    }
}

/**
 Main tab bar content styling
 */
class MunchTabBarContentView: ESTabBarItemContentView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
        insets.bottom = 4
        insets.top = 5

        textColor = UIColor(hex: "A0A0A0")
        highlightTextColor = UIColor.primary500

        iconColor = UIColor(hex: "A0A0A0")
        highlightIconColor = UIColor.primary500

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
