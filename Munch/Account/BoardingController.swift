//
// Created by Fuxing Loh on 16/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Crashlytics
import Kingfisher
import SnapKit

import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn

class AccountRootBoardingController: UINavigationController, UINavigationControllerDelegate {

    private let withCompletion: (AuthenticationState) -> Void

    init(withCompletion: @escaping (AuthenticationState) -> Void) {
        self.withCompletion = withCompletion
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [AccountBoardingController(withCompletion: withCompletion)]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AccountBoardingController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 56)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = .zero
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.black
        collectionView.register(BoardingCardCell.self, forCellWithReuseIdentifier: "BoardingCardCell")
        return collectionView
    }()

    private let headerIconLabel: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(named: "Onboarding-Icon"), for: .normal)
        button.imageEdgeInsets.right = 24
        button.setTitle("Munch", for: .normal)

        button.titleLabel?.font = UIFont.systemFont(ofSize: 36.0, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    private let headerView = HeaderView()
    private let bottomView = BottomView()

    private let withCompletion: (AuthenticationState) -> Void

    init(withCompletion: @escaping (AuthenticationState) -> Void) {
        self.withCompletion = withCompletion
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        headerView.cancelButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        bottomView.facebookButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        bottomView.googleButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func initViews() {
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)
        self.view.addSubview(headerIconLabel)
        self.view.addSubview(bottomView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        headerIconLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self.view).inset(24)
            make.top.equalTo(headerView.snp.bottom).inset(-12)
            make.height.equalTo(60)
        }

        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        bottomView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }

    private func dismiss(state: AuthenticationState) {
        switch state {
        case .loggedIn: fallthrough
        case .cancel:
            self.withCompletion(state)
            self.dismiss(animated: true)
        case .fail(let error):
            self.alert(error: error)
        }
    }

    @objc func action(_ sender: UIButton) {
        if sender == self.headerView.cancelButton {
            self.dismiss(state: .cancel)
        } else if sender == self.bottomView.facebookButton {
            FBSDKLoginManager().logIn(withReadPermissions: ["email", "public_profile", "user_friends"], from: self) { (result: FBSDKLoginManagerLoginResult!, error: Error!) in
                if let error = error {
                    Crashlytics.sharedInstance().recordError(error)
                    self.dismiss(state: .fail(error))
                    return
                }

                if result?.isCancelled ?? true {
                    self.dismiss(state: .cancel)
                    return
                }

                if result!.grantedPermissions.contains("email") && result!.grantedPermissions.contains("public_profile") {
                    if let token = FBSDKAccessToken.current()?.tokenString {
                        AccountAuthentication.login(facebook: token) { state in
                            self.dismiss(state: state)
                        }
                    } else {
                        self.dismiss(state: .cancel)
                    }
                }
            }
        } else if sender == self.bottomView.googleButton {
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().signIn()
        }
    }

    // MARK: Google Sign In
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            Crashlytics.sharedInstance().recordError(error)
            self.dismiss(state: .fail(error))
            return
        }

        if let authentication = user.authentication {
            AccountAuthentication.login(google: authentication.idToken, accessToken: authentication.accessToken) { state in
                self.dismiss(state: state)
            }
        } else {
            self.dismiss(state: .cancel)
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        AccountAuthentication.logout()
        self.dismiss(state: .cancel)
    }

    class BottomView: UIView {
        let facebookButton: ContinueButton = {
            let button = ContinueButton()
            button.labelView.text = "Continue with Facebook"
            button.labelView.textColor = .white

            button.iconView.image = UIImage(named: "Boarding-Facebook")
            button.iconView.tintColor = .white

            button.backgroundColor = UIColor(hex: "#4267b2")
            button.layer.cornerRadius = 3
            return button
        }()

        let googleButton: ContinueButton = {
            let button = ContinueButton()
            button.labelView.text = "Continue with Google"
            button.labelView.textColor = UIColor.black.withAlphaComponent(0.85)

            button.iconView.image = UIImage(named: "Boarding-Google")
            button.iconView.tintColor = .white

            button.backgroundColor = .white
            button.layer.cornerRadius = 3
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.black.withAlphaComponent(0.6).cgColor
            return button
        }()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.backgroundColor = .white
            self.addSubview(facebookButton)
            self.addSubview(googleButton)

            facebookButton.snp.makeConstraints { make in
                make.top.equalTo(self).inset(18)
                make.left.right.equalTo(self).inset(24)
                make.height.equalTo(44)
            }

            googleButton.snp.makeConstraints { make in
                make.left.right.equalTo(self).inset(24)
                make.height.equalTo(44)

                make.top.equalTo(facebookButton.snp.bottom).inset(-12)
                make.bottom.equalTo(self.safeArea.bottom).inset(18)
            }
        }

        class ContinueButton: UIButton {
            let iconView: UIImageView = {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                return imageView
            }()
            let labelView: UILabel = {
                let label = UILabel()
                label.textAlignment = .center
                label.font = .systemFont(ofSize: 15, weight: .regular)
                label.textColor = UIColor.black.withAlphaComponent(0.9)
                return label
            }()

            override init(frame: CGRect = .zero) {
                super.init(frame: frame)
                self.addSubview(iconView)
                self.addSubview(labelView)

                iconView.snp.makeConstraints { make in
                    make.top.bottom.equalTo(self)
                    make.left.equalTo(self).inset(10)
                    make.width.equalTo(26).priority(999)
                }

                labelView.snp.makeConstraints { make in
                    make.top.bottom.equalTo(self)
                    make.right.equalTo(self)
                    make.left.equalTo(iconView.snp.right)
                }
            }

            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class HeaderView: UIView {
        let cancelButton: UIButton = {
            let button = UIButton()
            button.setTitle("CANCEL", for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.titleEdgeInsets.right = 24
            button.contentHorizontalAlignment = .right
            return button
        }()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.addSubview(cancelButton)

            self.backgroundColor = .clear
            cancelButton.snp.makeConstraints {
                make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.height.equalTo(44)
                make.width.equalTo(90)
                make.right.equalTo(self)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccountBoardingController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "BoardingCardCell", for: indexPath)
    }
}

fileprivate class BoardingCardCell: UICollectionViewCell {
    let imageView = UIImageView()
    let headerLabel = UILabel()
    let descriptionLabel = UILabel()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(headerLabel)
        self.addSubview(descriptionLabel)
        self.initViews()
    }

    private func initViews() {
        let url = URL(string: "https://s3.dualstack.ap-southeast-1.amazonaws.com/munch-static/iOS/onboarding_1.jpg")
        imageView.kf.setImage(with: url)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        headerLabel.text = "Discover Delicious"
        headerLabel.textAlignment = .center
        headerLabel.font = UIFont.systemFont(ofSize: 28.0, weight: .semibold)
        headerLabel.textColor = UIColor.white
        headerLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(descriptionLabel.snp.top).inset(-18)
        }

        descriptionLabel.text = "Explore every corner of Singapore and discover delicious with Munch"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        descriptionLabel.textColor = UIColor.white
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(self).inset(30)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}