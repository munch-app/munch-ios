//
// Created by Fuxing Loh on 16/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Kingfisher
import SnapKit
import Auth0
import Lock

class AccountBoardingController: UIViewController {
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
    private let headerView = BoardingHeader()
    private let bottomView = BottomView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        headerView.cancelButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        bottomView.signIn.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        bottomView.signUp.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func initViews() {
        self.view.backgroundColor = .black
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
            make.bottom.equalTo(self.view.safeArea.bottom)
        }
    }

    @objc func action(_ sender: UIButton) {
        if sender == self.headerView.cancelButton {
            self.dismiss(animated: true)
        } else if sender == self.bottomView.signIn {
            lock(screen: .login).present(from: self)
        } else if sender == self.bottomView.signUp {
            lock(screen: .signup).present(from: self)
        }
    }

    private func lock(screen: DatabaseScreen) -> Lock {
        return Lock.classic()
                .withConnections { connections in
                    connections.database(name: "Username-Password-Authentication", requiresUsername: false)
                    connections.social(name: "facebook", style: .Facebook)
                }
                .withOptions {
                    $0.initialScreen = screen
                    $0.closable = true
                    $0.oidcConformant = true
                    $0.scope = "openid profile email offline_access"
                    $0.audience = "https://api.munchapp.co/"

                }
                .withStyle {
                    $0.headerColor = .white
                    $0.headerCloseIcon = LazyImage(name: "Account-Close")
                    $0.title = "Munch Account"
                    $0.logo = LazyImage(name: "AppIcon")
                    $0.primaryColor = .primary
                }
                .onAuth { credentials in
                    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
                    if (credentialsManager.store(credentials: credentials)) {
                        self.dismiss(animated: true)
                    } else {
                        self.alert(title: "Login Failure", message: "Unable to store the user credentials.")
                    }
                }
    }

    class BottomView: UIView {
        let signIn: UIButton = {
            let button = UIButton()
            button.setTitle("SIGN IN", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .primary
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            return button
        }()

        let signUp: UIButton = {
            let button = UIButton()
            button.setTitle("SIGN UP", for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = .white
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            return button
        }()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.backgroundColor = .black
            self.addSubview(signUp)
            self.addSubview(signIn)

            signIn.snp.makeConstraints { make in
                make.left.equalTo(self)
                make.right.equalTo(signUp.snp.left)
                make.width.equalTo(signUp.snp.width).priority(999)
                make.top.bottom.equalTo(self)
                make.height.equalTo(56)
            }

            signUp.snp.makeConstraints { make in
                make.right.equalTo(self)
                make.left.equalTo(signIn.snp.right)
                make.width.equalTo(signIn.snp.width).priority(999)
                make.top.bottom.equalTo(self)
                make.height.equalTo(56)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class BoardingHeader: UIView {
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
            cancelButton.snp.makeConstraints { make in
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
}

extension AccountBoardingController: UICollectionViewDataSource, UICollectionViewDelegate {
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
        let url = URL(string: "https://s3-ap-southeast-1.amazonaws.com/munch-static/iOS/onboarding_1.jpg")
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
            make.bottom.equalTo(self).inset(64)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}