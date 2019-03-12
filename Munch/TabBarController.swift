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

enum MunchTabBarItem {
    case Discover
    case Feed
    case Profile

    var index: Int {
        switch self {
        case .Discover: return 0
        case .Feed: return 1
        case .Profile: return 2
        }
    }

    var name: String {
        switch self {
        case .Discover: return "Discover"
        case .Feed: return "Feed"
        case .Profile: return "Profile"
        }
    }

    var image: String {
        switch self {
        case .Discover: return "TabBar_Discover"
        case .Feed: return "TabBar_Feed"
        case .Profile: return "TabBar_Profile"
        }
    }
}

extension MunchTabBarItem {
    fileprivate var ui: UITabBarItem {
        return UITabBarItem(title: self.name, image: UIImage(named: self.image), tag: 0)
    }
}

enum InitialViewProvider {

    /**
     Main tab controllers for Munch App
     */
    static func main() -> MunchTabBarController {
        return MunchTabBarController()
    }

    fileprivate static func search() -> SearchRootController {
        let controller = SearchRootController()
        controller.tabBarItem = MunchTabBarItem.Discover.ui
        return controller
    }

    fileprivate static func feed() -> FeedRootController {
        let controller = FeedRootController()
        controller.tabBarItem = MunchTabBarItem.Feed.ui
        return controller
    }

    fileprivate static func profile() -> ProfileRootController {
        let controller = ProfileRootController()
        controller.tabBarItem = MunchTabBarItem.Profile.ui
        return controller
    }
}

// MARK: TabBar Selecting
extension MunchTabBarController: UITabBarControllerDelegate {
    override var selectedIndex: Int {
        didSet {
            self.previousController = self.viewControllers![selectedIndex]
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        switch viewController {
        case is ProfileRootController where Authentication.isAuthenticated():
            return true

        case is ProfileRootController where !Authentication.isAuthenticated():
            Authentication.requireAuthentication(controller: self) { state in
                guard case .loggedIn = state else {
                    return
                }

                tabBarController.selectedViewController = viewController
            }
            return false

        case let root as SearchRootController where self.previousController == viewController:
            guard let controller = root.topViewController as? SearchController else {
                return true
            }

            if (controller.searchTableView.scrollToTop()) {
                controller.reset()
            }
            return true

        case let root as FeedRootController where self.previousController == viewController:
            guard let controller = root.topViewController as? FeedController else {
                return true
            }

            if (controller.scrollToTop()) {
                controller.reset()
            }
            return true
        default:
            return true
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.previousController = viewController
    }
}

// MARK: TabBar Styling
class MunchTabBarController: UITabBarController {
    var previousController: UIViewController!

    private let search = InitialViewProvider.search()
    private let feed = InitialViewProvider.feed()
    private let profile = InitialViewProvider.profile()

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.shadow(vertical: -2)

        tabBar.tintColor = UIColor.primary600
        tabBar.unselectedItemTintColor = UIColor.black.withAlphaComponent(0.7)

        self.delegate = self
        self.viewControllers = [search, feed, profile]
        self.previousController = self.viewControllers![0]
    }

    /**
     * Allows you to reset all tabs due to major state change.
     */
    func reset() {
        search.controller.reset()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}