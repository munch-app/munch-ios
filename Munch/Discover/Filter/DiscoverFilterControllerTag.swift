//
// Created by Fuxing Loh on 2/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import BEMCheckBox

class SearchSuggestTagController: UIViewController, UIGestureRecognizerDelegate {
    fileprivate let manager: DiscoverFilterControllerManager
    fileprivate let selectedType: String
    fileprivate var tags: [DiscoverFilterType]

    private let onExtensionDismiss: ((SearchQuery?) -> Void)

    private let headerView = SearchControllerSuggestTagHeaderView()
    private let bottomView = SearchControllerSuggestTagBottomView()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.contentInset.top = 7
        tableView.contentInset.bottom = 14
        tableView.separatorStyle = .none

        tableView.register(DiscoverFilterCellHeader.self, forCellReuseIdentifier: DiscoverFilterCellHeader.id)
        tableView.register(DiscoverFilterCellTag.self, forCellReuseIdentifier: DiscoverFilterCellTag.id)
        return tableView
    }()

    init(searchQuery: SearchQuery, type: String, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.manager = DiscoverFilterControllerManager(searchQuery: searchQuery)
        self.tags = manager.tags
        self.selectedType = type
        self.onExtensionDismiss = extensionDismiss

        super.init(nibName: nil, bundle: nil)
        self.initViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.bottomView.applyButton.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.bottomView.render(searchQuery: manager.searchQuery)
        self.manager.addUpdateHook { query in
            self.bottomView.render(searchQuery: query)
        }

        let index = self.tags.index { type in
            switch type {
            case .header(let title):
                if (title.lowercased() == self.selectedType.lowercased()) {
                    return true
                }
            default: break
            }
            return false
        }
        self.tableView.scrollToRow(at: .init(row: index ?? 0, section: 0), at: .top, animated: false)
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(bottomView)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.bottomView.snp.top)
        }

        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self.view)
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.navigationController?.popViewController(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(manager.searchQuery)
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchControllerSuggestTagHeaderView: UIView {
    fileprivate let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()
    fileprivate let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.titleEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .white
        self.addSubview(headerLabel)
        self.addSubview(cancelButton)

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.right.equalTo(self)

            make.width.equalTo(90)
            make.height.equalTo(44)
        }

        headerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)

            make.centerX.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchControllerSuggestTagBottomView: UIView {
    fileprivate let applyButton: UIButton = {
        let applyBtn = UIButton()
        applyBtn.layer.cornerRadius = 3
        applyBtn.backgroundColor = .primary
        applyBtn.setTitle("Loading...", for: .normal)
        applyBtn.setTitleColor(.white, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return applyBtn
    }()
    fileprivate var searchQuery: SearchQuery!

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(applyButton)

        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }
    }

    func render(searchQuery: SearchQuery) {
        applyButton.setTitle("Loading...", for: .normal)
        self.searchQuery = searchQuery
        self.perform(#selector(renderDidCommit(_:)), with: nil, afterDelay: 0.75)
    }

    @objc fileprivate func renderDidCommit(_ sender: Any) {
        MunchApi.discover.filterCount(query: searchQuery, callback: { (meta, count) in
            if let count = count {
                if count == 0 {
                    self.applyButton.setTitle("No Results", for: .normal)
                } else if count > 100 {
                    self.applyButton.setTitle("Apply (100+ Restaurants)", for: .normal)
                } else if count <= 10 {
                    self.applyButton.setTitle("Apply (\(count) Restaurants)", for: .normal)
                } else {
                    let rounded = count / 10 * 10
                    self.applyButton.setTitle("Apply (\(rounded)+ Restaurants)", for: .normal)
                }
            }
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchSuggestTagController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tags[indexPath.row] {
        case .header(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellHeader.id) as! DiscoverFilterCellHeader
            cell.render(title: title)
            return cell

        case .tag(let tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellTag.id) as! DiscoverFilterCellTag
            let text = tag.name ?? ""
            cell.render(title: text, selected: manager.isSelected(tag: text))
            return cell
        default: return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch tags[indexPath.row] {
        case .tag(let tag):
            let text = tag.name ?? ""
            manager.select(tag: text, selected: !manager.isSelected(tag: text))
            tableView.reloadRows(at: [indexPath], with: .none)
        default: return
        }
    }
}