//
//  AccountController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import AWSAuthCore
import AWSAuthUI
import AWSFacebookSignIn

class AccountController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        goToLogin()
    }
    
    func goToLogin() {
        print("Handling optional sign-in.")
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            let config = AWSAuthUIConfiguration()
            config.addSignInButtonView(class: AWSFacebookSignInButton.self)
            config.canCancel = true
            
            AWSAuthUIViewController.presentViewController(with: self.navigationController!,
                                                          configuration: config,
                                                          completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                                                            if error != nil {
                                                                print("Error occurred: \(error)")
                                                            } else {
//                                                                self.onSignIn(true)
                                                            }
            })
        }
    }
}
