//
//  SearchControllerSuggest.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON
import TPKeyboardAvoiding

class SearchSuggestRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [SearchSuggestController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchSuggestController: UIViewController {
    private let onExtensionDismiss: ((SearchQuery?) -> Void)
    let manager: SearchControllerSuggestManager

    private let headerView = SearchSuggestHeaderView()
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.contentInset.top = 7
        tableView.contentInset.bottom = 7
        tableView.separatorStyle = .none
        return tableView
    }()

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.onExtensionDismiss = extensionDismiss
        self.manager = .init(searchQuery: searchQuery)
        super.init(nibName: nil, bundle: nil)

        self.registerCell()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.headerView.textField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)

        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.headerView.textField.addTarget(self, action: #selector(textFieldShouldReturn(_:)), for: .editingDidEndOnExit)

        self.headerView.tagCollection.render(query: manager.searchQuery)

        self.headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        self.tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.headerView.textField.resignFirstResponder()
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func textFieldDidChange(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 1.0)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 2 {
            // TODO Multi Search and Convert
        } else {
            self.tableView.reloadData()
        }
    }

    @objc func textFieldShouldReturn(_ sender: Any) -> Bool {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        textFieldDidCommit(textField: headerView.textField)
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchSuggestController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchSuggestCellHeader.self, forCellReuseIdentifier: SearchSuggestCellHeader.id)
        tableView.register(SearchSuggestCellLocation.self, forCellReuseIdentifier: SearchSuggestCellLocation.id)
        tableView.register(SearchSuggestCellTag.self, forCellReuseIdentifier: SearchSuggestCellTag.id)
        tableView.register(SearchSuggestCellTiming.self, forCellReuseIdentifier: SearchSuggestCellTiming.id)
    }

    var items: [SearchSuggestType] {
        return manager.items
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .header(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellHeader.id) as! SearchSuggestCellHeader
            cell.render(title: title)
            return cell
        case .location(let locations):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellLocation.id) as! SearchSuggestCellLocation
            cell.render(locations: locations, controller: self)
            return cell

        case .tag(let tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellTag.id) as! SearchSuggestCellTag
            let text = tag.name ?? ""
            cell.render(title: text, selected: manager.isSelected(tag: text))
            return cell

        case .time(let timings):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchSuggestCellTiming.id) as! SearchSuggestCellTiming
            cell.render(timings: timings, controller: self)
            return cell

        default: return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .tag(let tag):
            let text = tag.name ?? ""
            manager.select(tag: text, selected: !manager.isSelected(tag: text))
            tableView.reloadRows(at: [indexPath], with: .none)
        default: return
        }
    }
}

fileprivate class SearchSuggestHeaderView: UIView, SearchFilterTagDelegate {
    fileprivate var controller: SearchSuggestController!
    fileprivate let textField: SearchTextField = {
        let textField = SearchTextField()
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .search

        textField.layer.cornerRadius = 4
        textField.color = UIColor(hex: "2E2E2E")
        textField.backgroundColor = UIColor.init(hex: "EBEBEB")

        textField.leftImage = UIImage(named: "SC-Search-18")
        textField.leftImagePadding = 3
        textField.leftImageWidth = 32
        textField.leftImageSize = 18

        textField.placeholder = "Search Anything"
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        return textField
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
    fileprivate let tagCollection = SearchFilterTagCollection()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(textField)
        self.addSubview(cancelButton)
        self.addSubview(tagCollection)

        self.backgroundColor = .white

        textField.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top).inset(8)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(cancelButton.snp.left)
            make.height.equalTo(36)
        }

        cancelButton.snp.makeConstraints { make in
            make.width.equalTo(90)
            make.top.equalTo(self.safeArea.top).inset(8)
            make.right.equalTo(self)
            make.height.equalTo(36)
        }

        tagCollection.delegate = self
        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(textField.snp.bottom).inset(-9)
            make.bottom.equalTo(self).inset(8)
            make.height.equalTo(34)
        }
    }

    func tagCollection(selectedLocation name: String, for tagCollection: SearchFilterTagCollection) {
    }

    func tagCollection(selectedHour name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.select(hour: name)
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedPrice name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.resetPrice()
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func tagCollection(selectedTag name: String, for tagCollection: SearchFilterTagCollection) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
            self.controller.manager.reset(tags: [name.lowercased()])
        })
        addAlert(removeAll: alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.controller.present(alert, animated: true)
    }

    func addAlert(removeAll alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Remove All", style: .destructive) { action in
            self.controller.manager.reset()
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 1.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
