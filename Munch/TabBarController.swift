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

enum InitialViewProvider {

    /**
     Main tab controllers for Munch App
     */
    static func main() -> MunchTabBarController {
        return MunchTabBarController()
    }

    fileprivate static func home() -> HomeRootController {
        let controller = HomeRootController()
        controller.tabBarItem = UITabBarItem(title: "Home".localized(), image: UIImage(named: "TabBar_Home"), tag: 0)
        return controller
    }

    fileprivate static func search() -> SearchRootController {
        let controller = SearchRootController()
        controller.tabBarItem = UITabBarItem(title: "Search".localized(), image: UIImage(named: "TabBar_Search"), tag: 0)
        return controller
    }

    fileprivate static func profile() -> ProfileRootController {
        let controller = ProfileRootController()
        controller.tabBarItem = UITabBarItem(title: "Profile".localized(), image: UIImage(named: "TabBar_Profile"), tag: 0)
        return controller
    }
}

// MARK: TabBar Selecting
extension MunchTabBarController {
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
            // TODO
//            if let controller = root.topViewController as? SearchController {
//                if (self.previousController == viewController) {
//                    sameTabCounter += 1
//                    if (sameTabCounter >= 2) {
//                        controller.scrollsToTop(animated: true)
//                    }
//                } else {
//                    sameTabCounter = 0
//                }
//                self.previousController = viewController
//            }
            return true

        default: return true
        }
    }
}

// MARK: TabBar Styling
class MunchTabBarController: UITabBarController, UITabBarControllerDelegate {
    var previousController: UIViewController?
    var sameTabCounter = 0

    let home = InitialViewProvider.home()
    let search = InitialViewProvider.search()
    let profile = InitialViewProvider.profile()

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.shadow(vertical: -2)

        self.delegate = self
        self.viewControllers = [home, search, profile]
    }

    var homeController: HomeController {
        return home.controller
    }

    var searchController: SearchController {
        return search.controller
    }

    var profileController: UIViewController {
        return profile.controller
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}