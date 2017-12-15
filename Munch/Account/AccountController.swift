//
//  AccountController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import Auth0
import Lock

import NVActivityIndicatorView

class AccountController: UINavigationController {

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [AccountProfileController()]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AccountProfileController: UIViewController {
    private let headerView = HeaderView()
    private let tableView = UITableView()
    private var userInfo: UserInfo?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if userInfo == nil {
            let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
            if (credentialsManager.hasValid()) {
                self.reloadProfile(credentialsManager: credentialsManager)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        self.registerCell()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.settingButton.addTarget(self, action: #selector(actionSetting(_:)), for: .touchUpInside)
        self.headerView.settingButton.isHidden = true

        // Check if user is logged in, push to AccountAuthenticateController if not
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        if credentialsManager.hasValid() {
            self.reloadProfile()
        } else {
            navigationController?.pushViewController(AccountBoardingController(), animated: false)
        }
    }

    @objc func actionSetting(_ sender: Any) {
        let controller = AccountSettingController()
        controller.userInfo = self.userInfo
        navigationController?.pushViewController(controller, animated: true)
    }

    private func reloadProfile(credentialsManager: CredentialsManager = CredentialsManager(authentication: Auth0.authentication())) {
        self.headerView.settingButton.isHidden = true
        self.userInfo = nil
        self.tableView.reloadData()

        credentialsManager.credentials { error, credentials in
            guard let accessToken = credentials?.accessToken else {
                return
            }

            Auth0.authentication()
                    .userInfo(withAccessToken: accessToken)
                    .start { result in
                        switch (result) {
                        case .success(let userInfo):
                            DispatchQueue.main.async {
                                self.headerView.settingButton.isHidden = false
                                self.userInfo = userInfo
                                self.tableView.reloadData()
                            }
                        case .failure(let error):
                            self.alert(title: "Fetch Profile Error", error: error)
                        }
                    }
        }
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 40
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }

    private class HeaderView: UIView {
        let titleView = UILabel()
        let settingButton = UIButton()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(titleView)
            self.addSubview(settingButton)

            titleView.text = "Profile"
            titleView.font = .systemFont(ofSize: 17, weight: .medium)
            titleView.textAlignment = .center
            titleView.snp.makeConstraints { make in
                make.centerX.equalTo(self)
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.height.equalTo(44)
            }

            settingButton.setImage(UIImage(named: "NavigationBar-Setting"), for: .normal)
            settingButton.tintColor = .black
            settingButton.contentHorizontalAlignment = .right
            settingButton.imageEdgeInsets.right = 24
            settingButton.snp.makeConstraints { make in
                make.right.equalTo(self)
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.width.equalTo(64)
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

fileprivate enum AccountCellType {
    // Profile: Images, Person Name
    case loading
    case profile(UserInfo)
}

extension AccountProfileController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: AccountLoadingCell.self)
        register(cellClass: ProfileInfoCell.self)
    }

    private var items: [(String?, [AccountCellType])] {
        if let userInfo = self.userInfo {
            return [(nil, [AccountCellType.profile(userInfo)])]
        } else {
            return [(nil, [AccountCellType.loading])]
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].0
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = .white
        header.textLabel!.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.85)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func dequeue(cellClass: UITableViewCell.Type) -> UITableViewCell {
            let identifier = String(describing: cellClass)
            return tableView.dequeueReusableCell(withIdentifier: identifier)!
        }

        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case .loading:
            return dequeue(cellClass: AccountLoadingCell.self)
        case .profile(let userInfo):
            let cell = dequeue(cellClass: ProfileInfoCell.self) as! ProfileInfoCell
            cell.render(userInfo: userInfo)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.section].1[indexPath.row]
        switch item {
        default:
            return
        }
    }
}

fileprivate class ProfileInfoCell: UITableViewCell {
    let profileImageView = ShimmerImageView()
    let nameLabel = UILabel()
    let emailLabel = UILabel()

//    let editButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initViews()
    }

    private func initViews() {
        self.addSubview(profileImageView)
        self.addSubview(nameLabel)
        self.addSubview(emailLabel)
//        self.addSubview(editButton)

        profileImageView.snp.makeConstraints { make in
            make.height.width.equalTo(100).priority(999)
            make.top.bottom.equalTo(self).inset(24).priority(999)
            make.left.equalTo(self).inset(24)
        }

        nameLabel.text = "Name"
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = .black
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).inset(-24)
            make.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(24)
            make.height.equalTo(34)
        }

        emailLabel.text = "Email"
        emailLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        emailLabel.textColor = .black
        emailLabel.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).inset(-24)
            make.right.equalTo(self).inset(24)
            make.top.equalTo(nameLabel.snp.bottom)
            make.height.equalTo(20)
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()
//        editButton.setTitle("Edit Profile", for: .normal)
//        editButton.setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .normal)
//        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
//        editButton.layer.cornerRadius = 3
//        editButton.layer.borderWidth = 1.0
//        editButton.layer.borderColor = UIColor.black.withAlphaComponent(0.45).cgColor
//        editButton.snp.makeConstraints { make in
//            make.left.equalTo(profileImageView.snp.right).inset(-24)
//            make.right.equalTo(self).inset(24)
//            make.top.equalTo(emailLabel.snp.bottom).inset(-5)
//        }
    }

    func render(userInfo: UserInfo) {
        if let profileImage = userInfo.picture?.absoluteString {
            profileImageView.render(images: ["original": profileImage])
        }
        nameLabel.text = userInfo.name
        emailLabel.text = userInfo.email
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AccountLoadingCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let indicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 35), type: .ballBeat, color: .primary, padding: 0)
        indicator.startAnimating()
        self.addSubview(indicator)

        let margin = (UIScreen.main.bounds.height / 2.0) - 64.0
        indicator.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(margin)
            make.centerX.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}