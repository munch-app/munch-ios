//
// Created by Fuxing Loh on 20/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import Auth0
import Lock

class AccountSettingController: UIViewController, UIGestureRecognizerDelegate, SFSafariViewControllerDelegate {
    private let headerView = HeaderView()
    private let tableView = UITableView()
    var userInfo: UserInfo!

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

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
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

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }
    }

    private func logout() {
        self.userInfo = nil
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        if (credentialsManager.clear()) {
            print("Removed Credentials")
        }
        navigationController?.pushViewController(AccountBoardingController(), animated: false)
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    private class HeaderView: UIView {
        let backButton = UIButton()
        let titleView = UILabel()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(titleView)
            self.addSubview(backButton)

            titleView.text = "Setting"
            titleView.font = .systemFont(ofSize: 17, weight: .regular)
            titleView.textAlignment = .center
            titleView.snp.makeConstraints { make in
                make.centerX.equalTo(self)
                make.top.equalTo(self).inset(20)
                make.bottom.equalTo(self)
            }

            backButton.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
            backButton.tintColor = .black
            backButton.imageEdgeInsets.left = 18
            backButton.contentHorizontalAlignment = .left
            backButton.snp.makeConstraints { make in
                make.top.equalTo(self).inset(20)
                make.left.equalTo(self)
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

fileprivate enum SettingCellType {
    // Profile: Images, Person Name
    case loading
    case instagramConnect
    case logout
}

extension AccountSettingController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: AccountLoadingCell.self)
        register(cellClass: SettingInstagramCell.self)
        register(cellClass: SettingLogoutCell.self)
    }

    private var items: [(String?, [SettingCellType])] {
        return [
            ("Content Partner", [SettingCellType.instagramConnect]),
            ("Account", [SettingCellType.logout])
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
        case .loading:
            return dequeue(cellClass: AccountLoadingCell.self)
        case .instagramConnect:
            return dequeue(cellClass: SettingInstagramCell.self)
        case .logout:
            return dequeue(cellClass: SettingLogoutCell.self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.section].1[indexPath.row]
        switch item {
        case .logout:
            self.logout()
        case .instagramConnect:
            // Safari http://partner.munchapp.co
            let safari = SFSafariViewController(url: URL(string: "http://partner.munchapp.co")!)
            safari.delegate = self
            present(safari, animated: true, completion: nil)
        default:
            return
        }
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

        connectLabel.text = "Manage"
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