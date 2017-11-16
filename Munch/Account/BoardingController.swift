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
    let appImageView = UIImageView()
    let titleView = UILabel()
    let continueButton = UIButton()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
    }

    private func initViews() {
        self.view.backgroundColor = .white
        let headerView = BoardingHeader()
        let boxView = UIView()

        self.view.addSubview(headerView)
        self.view.addSubview(boxView)

        boxView.addSubview(appImageView)
        boxView.addSubview(titleView)
        boxView.addSubview(continueButton)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }

        boxView.snp.makeConstraints { make in
            make.centerY.equalTo(self.view)
            make.left.right.equalTo(self.view).inset(24)
        }

        appImageView.image = UIImage(named: "AppIconLarge")
        appImageView.contentMode = .scaleAspectFit
        appImageView.clipsToBounds = true
        appImageView.snp.makeConstraints { make in
            make.left.right.equalTo(boxView)
            make.top.equalTo(boxView)
            make.height.equalTo(150)
        }

        titleView.text = "Some text for on boarding."
        titleView.textAlignment = .center
        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(boxView)
            make.top.equalTo(appImageView.snp.bottom).inset(-16)
            make.bottom.equalTo(continueButton.snp.top).inset(-24)
        }

        continueButton.addTarget(self, action: #selector(actionContinue(_:)), for: .touchUpInside)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .primary
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        continueButton.layer.cornerRadius = 3
        continueButton.layer.borderWidth = 1.0
        continueButton.layer.borderColor = UIColor.primary.cgColor
        continueButton.snp.makeConstraints { make in
            make.left.right.equalTo(boxView)
            make.bottom.equalTo(boxView)
            make.height.equalTo(48)
        }

    }

    @objc func actionContinue(_ sender: Any) {
        lock(screen: .signup).present(from: self)
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
                    $0.scope = "openid profile email"

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
                    credentialsManager.store(credentials: credentials)
                    self.navigationController?.popViewController(animated: false)
                }
    }

    class BoardingHeader: UIView {
        let titleView = UILabel()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(titleView)

            titleView.text = "Account"
            titleView.font = .systemFont(ofSize: 17, weight: .regular)
            titleView.textAlignment = .center
            titleView.snp.makeConstraints { make in
                make.top.equalTo(self).inset(20)
                make.left.right.equalTo(self)
                make.bottom.equalTo(self)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.hairlineShadow(height: 1.0)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
