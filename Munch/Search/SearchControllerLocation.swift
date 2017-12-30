//
// Created by Fuxing Loh on 5/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON
import TPKeyboardAvoiding

class SearchLocationController: UIViewController {
    private let filterManager: SearchFilterManager
    private let onExtensionDismiss: ((SearchQuery?) -> Void)

    private let headerView = SearchLocationHeaderView()
    private let tableView: TPKeyboardAvoidingTableView = {
        let tableView = TPKeyboardAvoidingTableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 12
        tableView.separatorInset.left = 24
        return tableView
    }()

    // Suggestion Result
    private var results: [LocationType]?

    required init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.filterManager = SearchFilterManager(searchQuery: searchQuery)
        self.onExtensionDismiss = extensionDismiss
        super.init(nibName: nil, bundle: nil)

        self.registerCell()
        self.initViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        self.headerView.textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.headerView.textField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.navigationController?.popViewController(animated: true)
    }

    @objc func textFieldDidChange(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 0.3)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 2 {
            MunchApi.locations.suggest(text: text, callback: { (meta, results) in
                self.results = results.flatMap { result in
                    if let location = result as? Location {
                        return LocationType.location(location)
                    } else if let container = result as? Container {
                        return LocationType.container(container)
                    } else {
                        return nil
                    }
                }

                self.tableView.reloadData()
            })
        } else {
            results = nil
            self.tableView.reloadData()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchLocationController: UITableViewDataSource, UITableViewDelegate {
    private var items: [(String?, [LocationType])] {
        if let results = results {
            return [("SUGGESTIONS", results)]
        } else {
            return [
                (nil, self.filterManager.locations),
                ("POPULAR LOCATIONS", self.filterManager.popularLocations ?? []),
            ]
        }
    }

    private func registerCell() {
        tableView.register(SearchLocationCell.self, forCellReuseIdentifier: SearchLocationCell.id)
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
        header.tintColor = UIColor(hex: "F1F1F1")
        header.textLabel!.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchLocationCell.id) as! SearchLocationCell

        switch items[indexPath.section].1[indexPath.row] {
        case .nearby:
            cell.render(title: "Nearby")
        case .anywhere:
            cell.render(title: "Anywhere")
        case let .location(location):
            cell.render(title: location.name, type: "LOCATION")
        case let .container(container):
            cell.render(title: container.name, type: container.type?.uppercased())
        case let .recentLocation(location):
            cell.render(title: location.name, type: "RECENT")
        case let .recentContainer(container):
            cell.render(title: container.name, type: "RECENT")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func select(result: SearchResult?, save: Bool = true) {
            if result == nil {
                let searchQuery = self.filterManager.select(location: nil, save: false)
                self.onExtensionDismiss(searchQuery)
                self.navigationController?.popViewController(animated: true)
            } else if let location = result as? Location {
                let searchQuery = self.filterManager.select(location: location, save: save)
                self.onExtensionDismiss(searchQuery)
                self.navigationController?.popViewController(animated: true)
            } else if let container = result as? Container {
                let searchQuery = self.filterManager.select(container: container, save: save)
                self.onExtensionDismiss(searchQuery)
                self.navigationController?.popViewController(animated: true)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
        switch items[indexPath.section].1[indexPath.row] {
        case .nearby:
            select(result: nil)
        case .anywhere:
            select(result: SearchFilterManager.anywhere, save: false)
        case .location(let location):
            select(result: location)
        case .container(let container):
            select(result: container)
        case .recentContainer(let container):
            select(result: container)
        case .recentLocation(let location):
            select(result: location)
        }
    }
}

class SearchLocationCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let typeLabel: UILabel = {
        let typeLabel = UILabel()
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        typeLabel.textColor = UIColor(hex: "686868")
        typeLabel.textAlignment = .right
        return typeLabel
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        self.addSubview(typeLabel)


        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(16)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(typeLabel.snp.left).inset(-8)
        }

        typeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(title: String?, type: String? = nil) {
        self.titleLabel.text = title
        self.typeLabel.text = type
    }

    class var id: String {
        return "SearchLocationCell"
    }
}

class SearchLocationHeaderView: UIView {
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

        textField.placeholder = "Search Location"
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        return textField
    }()
    fileprivate let cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.titleEdgeInsets.right = 24
        cancelButton.contentHorizontalAlignment = .right
        return cancelButton
    }()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(textField)
        self.addSubview(cancelButton)

        self.backgroundColor = .white

        textField.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top).inset(8)
            make.bottom.equalTo(self).inset(11)
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
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
