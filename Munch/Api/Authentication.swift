//
// Created by Fuxing Loh on 7/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Moya
import RxSwift

import Firebase
import FirebaseAuth
import Crashlytics

public enum AuthenticationState {
    case loggedIn
    case cancel
    case fail(Error)
}

public class Authentication {
    private static let provider = MunchProvider<UserService>()

    public class func getToken(withCompletion: @escaping (_ token: String?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            currentUser.getIDTokenForcingRefresh(true) { idToken, error in
                // Handle Error if Any
                if let error = error {
                    Crashlytics.sharedInstance().recordError(error)
                    return
                }

                // Callback with id Token
                withCompletion(idToken)
            }
        } else {
            withCompletion(nil)
        }
    }

    public class func isAuthenticated() -> Bool {
        if let providers = Auth.auth().currentUser?.providerData {
            for provider in providers {
                if provider.providerID == "google.com" {
                    Auth.auth().currentUser?.delete()
                    self.logout()
                    return false
                }
            }
        }
        return UserProfile.instance != nil
    }

    public class func requireAuthentication(controller: UIViewController, withCompletion: @escaping (_ state: AuthenticationState) -> Void) {
        if isAuthenticated() {
            // If already authenticated, complete with logged in
            withCompletion(.loggedIn)
        } else {
            // If user is not logged in, preset boarding controller and try to login
            let boardingController = AccountRootBoardingController(withCompletion: withCompletion)
            controller.present(boardingController, animated: true)
        }
    }

    public class func login(facebook accessToken: String, withCompletion: @escaping(_ state: AuthenticationState) -> Void) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)

        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                if error.localizedDescription.starts(with: "An account already") {
                    // TODO Delete Account?
                    return
                }
                Crashlytics.sharedInstance().recordError(error)
                withCompletion(.fail(error))
                return
            }
            // User is now signed in
            authenticate(withCompletion: withCompletion)
        }
    }

    // Temporary Method to authenticate user silently due to migration of version
    class func authenticate(withCompletion: @escaping(_ state: AuthenticationState) -> Void) {
        provider.rx.request(.authenticate)
                .map { response throws -> UserData in
                    try response.map(data: UserData.self)
                }
                .subscribe { event in
                    switch event {
                    case let .success(userData):
                        UserProfile.instance = userData.profile
                        UserSetting.instance = userData.setting
                        withCompletion(.loggedIn)
                    case let .error(error):
                        withCompletion(.fail(error))
                    }
                }
    }

    public class func logout() {
        UserProfile.instance = nil
        UserSetting.instance = nil
        do {
            try Auth.auth().signOut()
        } catch {
            Crashlytics.sharedInstance().recordError(error)
        }
    }
}
