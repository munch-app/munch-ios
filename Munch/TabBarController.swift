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
        let controllers = [searchController(), profileController()]
        return TabBarController(controllers: controllers)
    }
    
    static func searchController() -> UIViewController {
        let searchStoryboard = UIStoryboard(name: "Search", bundle: nil)
        let searchController = searchStoryboard.instantiateInitialViewController()!
        searchController.tabBarItem = ESTabBarItem(MunchTabBarContentView(), image: UIImage(named: "icons8-Search-35"))
        return searchController
    }
    
    static func profileController() -> UIViewController {
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        let profileController = profileStoryboard.instantiateInitialViewController()!
        profileController.tabBarItem = ESTabBarItem(MunchTabBarContentView(), image: UIImage(named: "icons8-customer-35"))
        return profileController
    }
}

class TabBarController: ESTabBarController, UITabBarControllerDelegate {
    var previousController: UIViewController?
    
    init(controllers: [UIViewController]) {
        super.init(nibName: nil, bundle: nil)
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.hairlineShadow(height: -1.0)
        tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: -10)
        
        self.delegate = self
        self.viewControllers = controllers
    }
    
    override func viewWillLayoutSubviews() {
        var tabFrame = self.tabBar.frame
        tabFrame.size.height = 44
        tabFrame.origin.y = self.view.frame.size.height - 44
        self.tabBar.frame = tabFrame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if (self.previousController == viewController) {
            if let navigation = viewController as? UINavigationController {
                if let controller = navigation.topViewController as? SearchController {
                    controller.scrollToTop()
                }
            }
        }
        self.previousController = viewController
        return true
    }
}

/**
 Main tab bar content styling
 */
class MunchTabBarContentView: ESTabBarItemContentView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = UIFont.systemFont(ofSize: 9, weight: UIFont.Weight.regular)
        insets.bottom = 3
        insets.top = 3
        
        iconColor = UIColor.black.withAlphaComponent(0.75)
        textColor = UIColor.black.withAlphaComponent(0.75)
        
        highlightIconColor = UIColor.black
        highlightTextColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
