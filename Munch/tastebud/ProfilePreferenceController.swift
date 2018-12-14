//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift
import BEMCheckBox
import Toast_Swift

class ProfilePreferenceController: UIViewController {
    private let provider = MunchProvider<UserSearchPreferenceService>()
    private let disposeBag = DisposeBag()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.contentInset.bottom = 16
        tableView.separatorStyle = .none
        return tableView
    }()

    private var items: [(String?, [ProfilePreferenceType])] = [
        (nil, [.header]),
        ("Requirements",
                UserSearchPreference.requirements.map({ ProfilePreferenceType.requirement($0) })
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view)
        }
    }
}

enum ProfilePreferenceType {
    case header
    case requirement(Tag)
}

// MARK: TableView Cells
extension ProfilePreferenceController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.register(type: ProfilePreferenceHeader.self)
        self.tableView.register(type: ProfilePreferenceCellRequirement.self)
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let text = items[section].0 else {
            return 1
        }

        return FontStyle.h2.height(text: text, width: UIScreen.main.bounds.width - 48) + 32
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let text = items[section].0 else {
            return UIView()
        }
        return ProfilePreferenceCellHeader(text: text)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.section].1[indexPath.row] {
        case .header:
            return tableView.dequeue(type: ProfilePreferenceHeader.self)

        case .requirement(let tag):
            let cell = tableView.dequeue(type: ProfilePreferenceCellRequirement.self)
            cell.nameLabel.text = tag.name
            cell.checkBox.setOn(UserSearchPreference.isSelected(tag: tag), animated: false)
            return cell
        }

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch items[indexPath.section].1[indexPath.row] {
        case .requirement(let tag):
            var preference = UserSearchPreference.instance ?? UserSearchPreference(requirements: [], updatedMillis: 0)
            if preference.requirements.contains(where: { $0.tagId == tag.tagId }) {
                preference.requirements.removeAll(where: { $0.tagId == tag.tagId })
            } else {
                preference.requirements.append(tag)
            }

            UserSearchPreference.instance = preference

            provider.rx.request(.put(preference)).subscribe { event in
                switch event {
                case .success:
                    self.view.makeToast("Search Preference Updated")
                    self.tableView.reloadData()
                    if let controller = self.tabBarController as? MunchTabBarController {
                        controller.reset()
                    }

                case .error(let error):
                    self.alert(error: error)
                }
            }.disposed(by: disposeBag)
        default:
            return

        }
    }
}

class ProfilePreferenceCellHeader: UIView {
    let label = UILabel(style: .h2)
            .with(text: "Permanent Requirements")
            .with(numberOfLines: 0)

    init(text: String) {
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.addSubview(label)

        label.text = text
        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.centerY.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfilePreferenceCellRequirement: UITableViewCell {
    fileprivate let nameLabel = UILabel(size: 17, weight: .medium, color: .black)

    fileprivate let checkBox: BEMCheckBox = {
        let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        checkButton.boxType = .square
        checkButton.lineWidth = 2
        checkButton.cornerRadius = 1
        checkButton.tintColor = UIColor(hex: "444444")
        checkButton.animationDuration = 0.25
        checkButton.isEnabled = false

        checkButton.onCheckColor = .white
        checkButton.onTintColor = .primary500
        checkButton.onFillColor = .primary500
        return checkButton
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(nameLabel)
        self.addSubview(checkBox)

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(9)
            make.bottom.equalTo(self).inset(9)
            make.left.equalTo(self).inset(24)

            make.right.equalTo(checkBox.snp.left).inset(-16)
        }

        checkBox.snp.makeConstraints { make in
            make.top.bottom.equalTo(nameLabel)
            make.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfilePreferenceHeader: UITableViewCell {
    let label = UILabel(style: .h2)
            .with(text: "Tastebud Preference")
    let subLabel = UILabel(style: .h6)
            .with(text: "Customise your Tastebud on Munch for a better experience.")
            .with(numberOfLines: 0)
    let container = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(container)
        container.addSubview(label)
        container.addSubview(subLabel)

        container.backgroundColor = .whisper100
        container.layer.cornerRadius = 3

        container.snp.makeConstraints { maker in
            maker.left.right.top.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(8)
        }

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(container).inset(24)
            maker.top.equalTo(container).inset(24).priority(.high)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(container).inset(24)
            maker.top.equalTo(label.snp.bottom).inset(-8).priority(.high)
            maker.bottom.equalTo(container).inset(24).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}