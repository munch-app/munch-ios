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

import Auth0

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
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "SEARCH", image: UIImage(named: "TabBar-Search"))
        return controller
    }

    fileprivate static func account() -> UIViewController {
        let controller = AccountController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "PROFILE", image: UIImage(named: "TabBar-Profile"))
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
        tabBar.hairlineShadow(height: -1.0)
        tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: -10)
        
        self.delegate = self
        self.viewControllers = [searchController, accountController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if (viewController is AccountController) {
            if (CredentialsManager(authentication: Auth0.authentication()).hasValid()) {
                return true
            }

            // If user not authenticated, show boarding controller
            let controller = AccountBoardingController.init(onAuthenticate: {
                // If user is authenticated, assign account controller
                tabBarController.selectedViewController = self.accountController
            }, onCancel: nil)
            self.present(controller, animated: true)
            return false
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
        titleLabel.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        insets.bottom = 4
        insets.top = 5

        textColor = UIColor.black.withAlphaComponent(0.63)
        highlightTextColor = UIColor.primary500

        iconColor = UIColor.black.withAlphaComponent(0.6)
        highlightIconColor = UIColor.primary500

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
