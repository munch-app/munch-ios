//
//  TabBarController.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Localize_Swift
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

    fileprivate static func search() -> SearchRootController {
        let controller = SearchRootController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "tab.search".localized(), image: UIImage(named: "TabBar-Search"))
        return controller
    }

    fileprivate static func profile() -> ProfileRootController {
        let controller = ProfileRootController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "tab.profile".localized(), image: UIImage(named: "TabBar-Profile"))
        return controller
    }
}

// MARK: TabBar Selecting
extension TabBarController {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        switch viewController {
        case is ProfileRootController where Authentication.isAuthenticated():
            return true

        case is ProfileRootController where !Authentication.isAuthenticated():
            Authentication.requireAuthentication(controller: self) { state in
                switch state {
                case .loggedIn:
                    tabBarController.selectedViewController = viewController
                default: return
                }
            }
            return false

        case let root as SearchRootController:
            if let controller = root.topViewController as? SearchController {
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
            return true

        default: return true
        }
    }
}

// MARK: TabBar Styling
class TabBarController: ESTabBarController, UITabBarControllerDelegate {
    var previousController: UIViewController?
    var sameTabCounter = 0

    let searchRoot = InitialViewProvider.search()
    let profileRoot = InitialViewProvider.profile()

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.shadow(vertical: -2)
        tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: -10)

        self.delegate = self
        self.viewControllers = [searchRoot, profileRoot]
    }

    var searchController: SearchController {
        return searchRoot.searchController
    }

    var profileController: ProfileController {
        return profileRoot.profileController
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
