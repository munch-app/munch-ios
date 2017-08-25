//
//  AppDelegate.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import ESTabBarController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        // Sync cached data
        CachedSync.sync()
        
        // Select initial view provider to use
        self.window?.rootViewController = InitialViewProvider.main()
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if let tabBar = self.window?.rootViewController as? ESTabBarController {
            if let navigation = tabBar.selectedViewController as? UINavigationController {
                if let controller = navigation.topViewController as? DiscoverController {
                    controller.refreshExpiredQuery()
                }
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}


/**
 Initial view provider
 */
enum InitialViewProvider {
    
    /**
     Main tab controllers for Munch App
     */
    static func main() -> ESTabBarController {
        let tabController = ESTabBarController()
        tabController.tabBar.isTranslucent = false
        tabController.tabBar.backgroundColor = UIColor.white
        tabController.tabBar.shadowImage = UIImage()
        tabController.tabBar.backgroundImage = UIImage()
        tabController.tabBar.hairlineShadow(height: -1.0)
        
        // Discover
        let discoverStoryboard = UIStoryboard(name: "Discover", bundle: nil)
        let discoverController = discoverStoryboard.instantiateInitialViewController()!
        discoverController.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "DISCOVER", image: UIImage(named: "icons8-Search-35"))
        
//        // Profile
//        let profileController = UIViewController()
//        profileController.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "PROFILE", image: UIImage(named: "icons8-customer-35"))
        
        tabController.viewControllers = [discoverController]
        return tabController
    }
}

/**
 Main tab bar content styling
 */
class MunchTabBarContentView: ESTabBarItemContentView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = UIFont.systemFont(ofSize: 9, weight: UIFontWeightSemibold)
        insets.bottom = 3
        insets.top = 3
        
        iconColor = UIColor.black.withAlphaComponent(0.75)
        textColor = UIColor.black.withAlphaComponent(0.75)
        
        highlightIconColor = UIColor.primary
        highlightTextColor = UIColor.primary
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
