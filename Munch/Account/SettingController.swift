//
// Created by Fuxing Loh on 20/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import Toast_Swift

import Moya
import BEMCheckBox
import SnapKit

class AccountSettingController: UIViewController, UIGestureRecognizerDelegate, SFSafariViewControllerDelegate {
    private let headerView = HeaderView()
    private let tableView = UITableView()
    private var setting = UserSetting.instance

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
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }

    private func logout() {
        Authentication.logout()
        self.navigationController?.popToRootViewController(animated: true)
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
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.height.equalTo(44)
            }

            backButton.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
            backButton.tintColor = .black
            backButton.imageEdgeInsets.left = 18
            backButton.contentHorizontalAlignment = .left
            backButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
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

enum SettingCellType {
    // Profile: Images, Person Name
    case loading
    case instagramConnect
    case feedback
    case logout

    case preferenceTag(String)
}

extension AccountSettingController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: SettingInstagramCell.self)
        register(cellClass: SettingLogoutCell.self)
        register(cellClass: SettingFeedbackCell.self)
        register(cellClass: SettingPreferenceTagCell.self)
    }

    private var items: [(String?, [SettingCellType])] {
        return [
            ("CONTENT PARTNER", [
                SettingCellType.instagramConnect
            ]),
            ("SEARCH PREFERENCE", [
                SettingCellType.preferenceTag("Halal"),
                SettingCellType.preferenceTag("Vegetarian Options"),
            ]),
            ("ACCOUNT", [
                SettingCellType.feedback,
                SettingCellType.logout,
            ]),
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
        header.textLabel!.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        header.textLabel!.textColor = UIColor.black
        header.backgroundView?.backgroundColor = .bgTag
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func dequeue(cellClass: UITableViewCell.Type) -> UITableViewCell {
            let identifier = String(describing: cellClass)
            return tableView.dequeueReusableCell(withIdentifier: identifier)!
        }

        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case .instagramConnect:
            return dequeue(cellClass: SettingInstagramCell.self)
        case .logout:
            return dequeue(cellClass: SettingLogoutCell.self)
        case .feedback:
            return dequeue(cellClass: SettingFeedbackCell.self)
        case .preferenceTag(let text):
            let cell = dequeue(cellClass: SettingPreferenceTagCell.self) as! SettingPreferenceTagCell
            cell.render(tag: text, checked: setting?.search.tags.contains(text.lowercased()) ?? false)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.section].1[indexPath.row]
        switch item {
        case .logout:
            self.logout()
        case .instagramConnect:
            let safari = SFSafariViewController(url: URL(string: "https://partner.munch.app")!)
            safari.delegate = self
            present(safari, animated: true, completion: nil)
        case .feedback:
            if let url = URL(string: "mailto:feedback@munch.app") {
                UIApplication.shared.open(url)
            }
        case .preferenceTag(let text):
            let tag = text.lowercased()

            if let setting = self.setting {
                if setting.search.tags.contains(tag) {
                    let cell = tableView.cellForRow(at: indexPath) as! SettingPreferenceTagCell
                    cell.checkButton.setOn(false, animated: true)

                    UserSetting.apply(search: { search in
                        var search = search
                        if let index = search.tags.index(of: tag) {
                            search.tags.remove(at: index)
                        }
                        return search
                    }) { result in
                        switch result {
                        case .success(let setting):
                            self.setting = setting
                            self.view.makeToast("Removed '\(tag.capitalized)' from Search Preference.", image: UIImage(named: "RIP-Toast-Close"), style: DefaultToastStyle)
                            (self.tabBarController as? TabBarController)?.discoverController?.reset(force: true)
                        case .error(let error):
                            self.alert(error: error)
                        }
                    }
                } else {
                    let cell = tableView.cellForRow(at: indexPath) as! SettingPreferenceTagCell
                    cell.checkButton.setOn(true, animated: true)

                    UserSetting.apply(search: { search in
                        var search = search
                        search.tags.append(tag)
                        return search
                    }) { result in
                        switch result {
                        case .success(let setting):
                            self.setting = setting
                            self.view.makeToast("Added '\(tag.capitalized)' to Search Preference.", image: UIImage(named: "RIP-Toast-Checkmark"), style: DefaultToastStyle)
                            (self.tabBarController as? TabBarController)?.discoverController?.reset(force: true)
                        case .error(let error):
                            self.alert(error: error)
                        }
                    }
                }
            }
        default:
            return
        }
    }
}

fileprivate class SettingInstagramCell: UITableViewCell {
    let titleView = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleView)

        titleView.text = "Manage Instagram Partner"
        titleView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleView.textColor = .black
        titleView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SettingPreferenceTagCell: UITableViewCell {
    private let titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleView.textColor = .black
        return titleView
    }()

    fileprivate let checkButton: BEMCheckBox = {
        let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        checkButton.boxType = .circle
        checkButton.lineWidth = 1.5
        checkButton.tintColor = UIColor(hex: "444444")
        checkButton.animationDuration = 0.25
        checkButton.isEnabled = false

        checkButton.onCheckColor = .white
        checkButton.onTintColor = .primary
        checkButton.onFillColor = .primary
        return checkButton
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleView)
        self.addSubview(checkButton)

        titleView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(checkButton.snp.left).inset(-12)
            make.top.bottom.equalTo(self).inset(10)
        }

        checkButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(10)
            make.right.equalTo(self).inset(18)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(tag: String, checked: Bool) {
        self.titleView.text = tag

        checkButton.setOn(checked, animated: false)
    }
}


fileprivate class SettingFeedbackCell: UITableViewCell {
    let titleView = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleView)

        titleView.text = "Send Feedback"
        titleView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleView.textColor = .black
        titleView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
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
        titleView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
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
