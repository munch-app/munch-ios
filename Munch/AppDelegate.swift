//
//  AppDelegate.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit

import Firebase
import Crashlytics
import GoogleSignIn

import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Select initial view provider to use
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = InitialViewProvider.main()
        self.window?.makeKeyAndVisible()

        // Configure Firebase
        FirebaseApp.configure()
        // Configure FBSDK
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        // Configure Google ID
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID

        return true
    }

    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        if FBSDKApplicationDelegate.sharedInstance().application(application, open: url, options: options) {
            return true
        }

        if GIDSignIn.sharedInstance().handle(url,
                sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                annotation: [:]) {
            return true
        }

        return false
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
        if let tabBar = self.window?.rootViewController as? TabBarController {
            if let navigation = tabBar.selectedViewController as? DiscoverNavigationalController {
                if let search = navigation.topViewController as? DiscoverController {
                    search.reset()
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
