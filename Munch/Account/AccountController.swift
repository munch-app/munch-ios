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

class AccountController: UINavigationController {
}

class AccountLoginController: UIViewController {
    // Auth0 Implementation
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

class AccountProfileController: UIViewController {
    private let headerView = AccountProfileHeader()
    private let tableView = UITableView()
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

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
        self.registerCell()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        // Check if user is logged in, push to AccountLoginController if not
        guard credentialsManager.hasValid() else {
            navigationController?.pushViewController(AccountLoginController(), animated: false)
            return
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
            make.height.equalTo(64)
        }
    }
}

fileprivate enum AccountCellType {
    // Profile: Images, Person Name
    case profile(String, [String: String])
    case instagramConnect
    case logout
}

extension AccountProfileController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: ProfileInfoCell.self)
        register(cellClass: SettingInstagramCell.self)
        register(cellClass: SettingLogoutCell.self)
    }

    private var items: [(String?, [AccountCellType])] {
        return [
            (nil, [AccountCellType.profile("Person Name", ["200x200": "https://www.gravatar.com/avatar/802ff8ce7495fbcaaebab1c8b06c243d?s=200&d=identicon&r=PG"])]),
            ("Content Partner", [AccountCellType.instagramConnect]),
            ("Account", [AccountCellType.logout])
        ]
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
        case let .profile(name, images):
            let cell = dequeue(cellClass: ProfileInfoCell.self) as! ProfileInfoCell
            cell.render(name: name, images: images)
            return cell
        case .instagramConnect:
            return dequeue(cellClass: SettingInstagramCell.self)
        case .logout:
            return dequeue(cellClass: SettingLogoutCell.self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // TODO
    }
}

fileprivate class AccountProfileHeader: UIView {
    let titleView = UILabel()

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(titleView)

        titleView.text = "Profile"
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

fileprivate class ProfileInfoCell: UITableViewCell {
    let profileImageView = UIImageView()
    let nameLabel = UILabel()
    let editButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initViews()
    }

    private func initViews() {
        self.addSubview(profileImageView)
        self.addSubview(nameLabel)
        self.addSubview(editButton)

        profileImageView.snp.makeConstraints { make in
            make.height.width.equalTo(100)
            make.top.left.bottom.equalTo(self).inset(24)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = .black
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).inset(-24)
            make.top.right.equalTo(self).inset(24)
            make.height.equalTo(33)
        }

        editButton.setTitle("Edit Profile", for: .normal)
        editButton.setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        editButton.layer.cornerRadius = 3
        editButton.layer.borderWidth = 1.0
        editButton.layer.borderColor = UIColor.black.withAlphaComponent(0.45).cgColor
        editButton.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).inset(-24)
            make.right.equalTo(self).inset(24)
            make.top.equalTo(nameLabel.snp.bottom).inset(-5)
        }
    }

    func render(name: String, images: [String: String]) {
        profileImageView.render(images: images)
        nameLabel.text = name
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SettingInstagramCell: UITableViewCell {
    let titleView = UILabel()
    let connectLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleView)
        self.addSubview(connectLabel)

        titleView.text = "Instagram Account"
        titleView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleView.textColor = .black
        titleView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }

        connectLabel.text = "Connect"
        connectLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        connectLabel.textColor = .primary
        connectLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SettingLogoutCell: UITableViewCell {
    let titleView = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleView)

        titleView.text = "Logout"
        titleView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleView.textColor = .black
        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
