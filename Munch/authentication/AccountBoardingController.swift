//
// Created by Fuxing Loh on 16/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Toast_Swift
import Localize_Swift

import Kingfisher
import SnapKit
import SwiftRichString

import FBSDKCoreKit
import FBSDKLoginKit

import Crashlytics
import UserNotifications

fileprivate struct OnboardingData {
    var backgroundImage: UIImage?
    var backgroundColor: UIColor
    var contextImage: UIImage?

    var title: String
    var description: String
}

class AccountRootBoardingController: UINavigationController, UINavigationControllerDelegate {

    private let withCompletion: (AuthenticationState) -> Void

    init(guestOption: Bool = false, withCompletion: @escaping (AuthenticationState) -> Void) {
        self.withCompletion = withCompletion
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [AccountBoardingController(guestOption: guestOption, withCompletion: withCompletion)]
        self.delegate = self

        AccountRootBoardingController.toShow = false
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var toShow: Bool {
        get {
            if Authentication.isAuthenticated() {
                return false
            }
            return UserDefaults.standard.string(forKey: "onboarding.load.version") != "2"
        }
        set(value) {
            UserDefaults.standard.set(value ? nil : "2", forKey: "onboarding.load.version")
        }
    }
}

class AccountBoardingController: UIViewController {
    fileprivate let dataList: [OnboardingData] = [
        OnboardingData(backgroundImage: UIImage(named: "Onboarding-Bg-1"),
                backgroundColor: UIColor(hex: "fcab5a"), contextImage: nil,
                title: "Welcome to Munch".localized(),
                description: "Whether you're looking for the perfect date spot or the hottest bar in town - Munch helps you answer the question:\n\n<bold>'What do you want to eat?'</bold>".localized()),

        OnboardingData(backgroundImage: UIImage(named: "Onboarding-Bg-2"),
                backgroundColor: UIColor(hex: "46b892"), contextImage: UIImage(named: "Onboarding-Singapore"),
                title: "Discover Delicious".localized(),
                description: "Explore thousands of restaurants, bars and hawkers in the app. Find places nearby or on the other end of the island.".localized()),

        OnboardingData(backgroundImage: UIImage(named: "Onboarding-Bg-3"),
                backgroundColor: UIColor(hex: "258edd"), contextImage: UIImage(named: "Onboarding-Collection"),
                title: "Never Forget".localized(),
                description: "Save places that you want to check out or create themed lists to keep track of places.".localized()),
    ]

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
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.pageIndicatorTintColor = UIColor(hex: "999999")
        control.currentPageIndicatorTintColor = UIColor(hex: "FFFFFF")
        return control
    }()
    private let headerIconLabel: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(named: "Onboarding-Icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.right = 24
        button.setTitle("Munch", for: .normal)

        button.titleLabel?.font = UIFont.systemFont(ofSize: 36.0, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    private let headerView: HeaderView
    private let bottomView: BottomView

    private let withCompletion: (AuthenticationState) -> Void

    init(guestOption: Bool, withCompletion: @escaping (AuthenticationState) -> Void) {
        self.withCompletion = withCompletion
        self.headerView = HeaderView(guestOption: guestOption)
        self.bottomView = BottomView(guestOption: guestOption)
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        headerView.cancelButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        bottomView.facebookButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        bottomView.guestButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        MunchAnalytic.setScreen("/profile/on-boarding")
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
        self.view.addSubview(pageControl)

        self.pageControl.numberOfPages = self.dataList.count
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

        pageControl.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(collectionView.snp.bottom).inset(22)
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
        case .loggedIn:
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                    options: authOptions,
//                    completionHandler: {_, _ in })

            fallthrough
        case .cancel:
            self.withCompletion(state)
            self.dismiss(animated: true)
        case .fail(let error):
            self.alert(title: "Account Sign In Error", error: error)
        }
    }

    @objc func action(_ sender: UIButton) {
        if sender == self.headerView.cancelButton || sender == self.bottomView.guestButton {
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
                    self.view.makeToastActivity(.center)

                    if let token = FBSDKAccessToken.current()?.tokenString {
                        Authentication.login(facebook: token) { state in
                            if case .loggedIn = state {
                                MunchAnalytic.logEvent("profile_login")
                            }
                            self.dismiss(state: state)
                        }
                    } else {
                        self.dismiss(state: .cancel)
                    }
                } else {
                    self.alert(title: "Authentication Error", message: "Failed to Authenticate because required permission not given.")
                }
            }
        }
    }

    class BottomView: UIView {
        let facebookButton: ContinueButton = {
            let button = ContinueButton()
            button.labelView.text = "Continue with Facebook".localized()
            button.labelView.textColor = .white

            button.iconView.image = UIImage(named: "Boarding-Facebook")
            button.iconView.tintColor = .white

            button.backgroundColor = UIColor(hex: "#4267b2")
            button.layer.cornerRadius = 3
            return button
        }()

        let guestButton: UIButton = {
            let button = UIButton()
            button.setTitle("Continue as Guest".localized(), for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            return button
        }()

        let agreeLabel: UILabel = {
            let label = UILabel()
            label.text = "By signing up, you agree to Munch's terms of use and privacy policy.".localized()
            label.numberOfLines = 0

            label.textColor = UIColor(hex: "3f3f3f")
            label.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            label.textAlignment = .center
            return label
        }()

        init(guestOption: Bool) {
            super.init(frame: CGRect.zero)
            self.backgroundColor = .white
            self.addSubview(facebookButton)
            self.addSubview(agreeLabel)

            facebookButton.snp.makeConstraints { make in
                make.top.equalTo(self).inset(18)
                make.left.right.equalTo(self).inset(24)
                make.height.equalTo(44)

                make.bottom.equalTo(agreeLabel.snp.top).inset(-12)
            }

            agreeLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self).inset(24)
                make.bottom.equalTo(self.safeArea.bottom).inset(12)
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
                label.font = .systemFont(ofSize: 15, weight: .medium)
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
            button.setTitle("CANCEL".localized(), for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.contentHorizontalAlignment = .right
            return button
        }()

        init(guestOption: Bool) {
            super.init(frame: CGRect.zero)
            self.addSubview(cancelButton)
            self.backgroundColor = .clear

            if guestOption {
                cancelButton.setTitle("SKIP".localized(), for: .normal)
                cancelButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

                cancelButton.layer.cornerRadius = 5
                cancelButton.layer.borderWidth = 1.0
                cancelButton.layer.borderColor = UIColor.white.cgColor

                cancelButton.contentEdgeInsets.left = 16
                cancelButton.contentEdgeInsets.right = 16

                cancelButton.snp.makeConstraints { make in
                    make.top.equalTo(self.safeArea.top).inset(6)
                    make.bottom.equalTo(self).inset(6)
                    make.height.equalTo(32)
                    make.right.equalTo(self).inset(24)
                }
            } else {
                cancelButton.titleEdgeInsets.right = 24

                cancelButton.snp.makeConstraints { make in
                    make.top.equalTo(self.safeArea.top)
                    make.bottom.equalTo(self)
                    make.height.equalTo(44)
                    make.width.equalTo(90)
                    make.right.equalTo(self)
                }
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
        return dataList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BoardingCardCell", for: indexPath) as! BoardingCardCell
        cell.render(data: dataList[indexPath.row])
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        pageControl.currentPage = pageNumber
    }
}

fileprivate class BoardingCardCell: UICollectionViewCell {
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "00000066")
        return view
    }()

    private let contextImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        return imageView
    }()
    private let titleView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0

        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 28.0, weight: .semibold)
        return label
    }()
    private let descriptionView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0

        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    static let boldStyle = Style {
        $0.alignment = .center
        $0.font = UIFont.systemFont(ofSize: 17, weight: .bold)
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(backgroundImageView)
        self.addSubview(overlayView)
        self.addSubview(contextImageView)
        self.addSubview(titleView)
        self.addSubview(descriptionView)

        initViews()
    }

    private func initViews() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        contextImageView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.width.height.equalTo(75)
            make.bottom.equalTo(titleView.snp.top).inset(-10)
        }

        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(descriptionView.snp.top).inset(-18)
        }

        descriptionView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(self).inset(70)
        }
    }

    fileprivate func render(data: OnboardingData) {
        self.backgroundImageView.image = data.backgroundImage
        self.contextImageView.image = data.contextImage

        self.titleView.text = data.title

        let myGroup = StyleGroup(["bold": BoardingCardCell.boldStyle])
        self.descriptionView.attributedText = data.description.set(style: myGroup)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
