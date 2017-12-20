//
// Created by Fuxing Loh on 16/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import Auth0
import Lock

class AccountBoardingController: UIViewController {
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 96)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        collectionView.register(BoardingCardCellOne.self, forCellWithReuseIdentifier: "BoardingCardCellOne")
        return collectionView
    }()
    private let headerView = BoardingHeader()
    private let bottomView = BottomView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
    }

    private func initViews() {
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        headerView.cancelButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(self.bottomView)
        }

        bottomView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
        }
    }

    @objc func action(_ sender: UIButton) {
        if sender == self.headerView.cancelButton {
            self.dismiss(animated: true)
        }
        // lock(screen: .signup).present(from: self)
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
                        self.navigationController?.popViewController(animated: false)
                    } else {
                        self.alert(title: "Login Failure", message: "Unable to store the user credentials.")
                    }
                }
    }

    class BottomView: UIView {
        let signUp: UIButton = {
            let button = UIButton()
            button.setTitle("Sign Up", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .primary
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            button.layer.cornerRadius = 3
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.primary.cgColor
            return button
        }()

        let signIn: UIButton = {
            let button = UIButton()
            button.setTitle("Sign In", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .primary
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            button.layer.cornerRadius = 3
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.primary.cgColor

            return button
        }()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.backgroundColor = .white
            self.addSubview(signUp)
            self.addSubview(signIn)

            signUp.snp.makeConstraints { make in
                make.left.equalTo(self).inset(24)
                make.right.equalTo(signIn.snp.left).inset(-24)
                make.width.equalTo(signIn.snp.width).priority(999)
                make.top.bottom.equalTo(self).inset(24)
                make.height.equalTo(48)
            }

            signIn.snp.makeConstraints { make in
                make.right.equalTo(self).inset(24)
                make.left.equalTo(signUp.snp.right).inset(-24)
                make.width.equalTo(signUp.snp.width).priority(999)
                make.top.bottom.equalTo(self).inset(24)
                make.height.equalTo(48)
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
            button.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
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
        return collectionView.dequeueReusableCell(withReuseIdentifier: "BoardingCardCellOne", for: indexPath)
    }
}

fileprivate class BoardingCardCellOne: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.initViews()
    }

    private func initViews() {
        imageView.image = UIImage(named: "AppIconLarge")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}