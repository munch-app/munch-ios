//
// Created by Fuxing Loh on 7/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Firebase
import FirebaseAuth
import Crashlytics

public enum AuthenticationState {
    case loggedIn
    case cancel
    case fail(Error)
}

public class AccountAuthentication {
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
        return Auth.auth().currentUser != nil
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
                Crashlytics.sharedInstance().recordError(error)
                withCompletion(.fail(error))
                return
            }
            // User is now signed in
            UserAccount.update(user: Auth.auth().currentUser!)
            withCompletion(.loggedIn)
        }
    }

    public class func login(google idToken: String, accessToken: String, withCompletion: @escaping(_ state: AuthenticationState) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                Crashlytics.sharedInstance().recordError(error)
                withCompletion(.fail(error))
                return
            }
            // User is now signed in
            UserAccount.update(user: Auth.auth().currentUser!)
            withCompletion(.loggedIn)
        }
    }

    public class func logout() {
        UserAccount.removeAll()
        do {
            try Auth.auth().signOut()
        } catch {
            Crashlytics.sharedInstance().recordError(error)
        }
    }
}

public class UserAccount {
    // Sub is JWT version of UserId
    public static var sub: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.sub")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.sub")
        }
    }

    public static var name: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.name")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.name")
        }
    }

    public static var email: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.email")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.email")
        }
    }

    public static var pictureUrl: String? {
        get {
            return UserDefaults.standard.string(forKey: "user.pictureUrl")
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: "user.pictureUrl")
        }
    }

    /**
     Check if the name is nil, if nil means that no user data yet loaded
     */
    public static var isEmpty: Bool {
        return name == nil
    }


    fileprivate class func update(user: UserInfo) {
        sub = user.uid
        name = user.displayName
        email = user.email
        pictureUrl = user.photoURL?.absoluteString

        Crashlytics.sharedInstance().setUserIdentifier(sub)
        Crashlytics.sharedInstance().setUserName(name)
        Crashlytics.sharedInstance().setUserEmail(email)
    }

    public class func removeAll() {
        self.sub = nil
        self.name = nil
        self.email = nil
        self.pictureUrl = nil
    }
}