//
// Created by Fuxing Loh on 20/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import Toast_Swift
import Localize_Swift

import Moya
import BEMCheckBox
import SnapKit

class ProfileSettingController: UIViewController, UIGestureRecognizerDelegate {
    private let headerView = ProfileSettingHeaderView()
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.backgroundColor = .void
        return tableView
    }()
    private var setting = UserSetting.instance

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        MunchAnalytic.setScreen("/profile/setting")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        self.registerCell()
        self.addTargets()

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }
}

fileprivate class ProfileSettingHeaderView: UIView {
    let backButton = UIButton()
    let titleView = UILabel(style: .navHeader)
            .with(text: "Settings")
            .with(alignment: .center)

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = .white
        self.addSubview(titleView)
        self.addSubview(backButton)

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

extension ProfileSettingController: SFSafariViewControllerDelegate {
    func addTargets() {
        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
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
}

enum SettingCellType {
    case separator
    case instagram
    case feedback
    case dtje
    case logout
}

extension ProfileSettingController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(type: SettingSeparatorCell.self)
        tableView.register(type: SettingTextCell.self)

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    private var items: [SettingCellType] {
        return [
            SettingCellType.separator,
            SettingCellType.instagram,
            SettingCellType.feedback,
            SettingCellType.separator,
            SettingCellType.dtje,
            SettingCellType.separator,
            SettingCellType.logout,
            SettingCellType.separator
        ]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .separator:
            return tableView.dequeue(type: SettingSeparatorCell.self)

        case .instagram:
            return tableView.dequeue(type: SettingTextCell.self)
                    .render(text: "Instagram Partner")
                    .render(separator: true, top: true, bot: false)

        case .logout:
            return tableView.dequeue(type: SettingTextCell.self)
                    .render(text: "Logout")
                    .render(separator: false, top: true, bot: true)

        case .feedback:
            return tableView.dequeue(type: SettingTextCell.self)
                    .render(text: "Send Feedback")
                    .render(separator: false, top: false, bot: true)

        case .dtje:
            return tableView.dequeue(type: SettingTextCell.self)
                    .render(text: "Notification: Don't Think, Just Eat")
                    .render(separator: false, top: true, bot: true)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .logout:
            self.logout()

        case .instagram:
            let safari = SFSafariViewController(url: URL(string: "https://partner.munch.app")!)
            safari.delegate = self
            present(safari, animated: true, completion: nil)

        case .feedback:
            if let url = URL(string: "mailto:feedback@munch.app") {
                UIApplication.shared.open(url)
            }

        case .dtje:
            let modal = SearchDTJEInfoController()
            let delegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: modal)
            modal.modalPresentationStyle = .custom
            modal.transitioningDelegate = delegate
            self.present(modal, animated: true)
        default:
            return
        }
    }
}

fileprivate class SettingSeparatorCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .void

        snp.makeConstraints { maker in
            maker.height.equalTo(32).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SettingTextCell: UITableViewCell {
    let titleView = UILabel(style: .regular)

    private let topLine = SeparatorLine()
    private let botLine = SeparatorLine()
    private let separatorLine = SeparatorLine()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleView)

        self.addSubview(separatorLine)
        self.addSubview(topLine)
        self.addSubview(botLine)

        titleView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(16)
        }

        separatorLine.snp.makeConstraints { maker in
            maker.bottom.right.equalTo(self)
            maker.left.equalTo(self).inset(24)
        }

        topLine.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self)
        }

        botLine.snp.makeConstraints { maker in
            maker.bottom.left.right.equalTo(self)
        }
    }

    func render(text: String) -> SettingTextCell {
        titleView.text = text
        return self
    }

    func render(separator: Bool, top: Bool, bot: Bool) -> SettingTextCell {
        separatorLine.isHidden = !separator
        topLine.isHidden = !top
        botLine.isHidden = !bot
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}