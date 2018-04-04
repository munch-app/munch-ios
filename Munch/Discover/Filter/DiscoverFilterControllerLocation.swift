//
// Created by Fuxing Loh on 3/4/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class DiscoverFilterControllerLocation: UIViewController {
    private let onExtensionDismiss: ((Location?, Container?) -> Void)

    fileprivate let headerView = DiscoverFilterLocationHeaderView()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.contentInset.bottom = 16
        tableView.separatorStyle = .none

        tableView.separatorInset.left = 24
        return tableView
    }()

    private var searchQuery: SearchQuery
    private var results: [(String?, [DiscoverFilterLocation])] = []
    private var searchResults: [DiscoverFilterLocation]? = nil

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((Location?, Container?) -> Void)) {
        self.onExtensionDismiss = extensionDismiss
        self.searchQuery = searchQuery
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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        self.headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        self.tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }

        MunchApi.discover.filter.locations.list { metaJSON, locations, containers in
            var list = [DiscoverFilterLocation]()
            for location in locations {
                list.append(.location(location))
            }

            for container in containers {
                list.append(.container(container))
            }

            let alpha: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "v", "x", "y", "z"]
            var letter: Character = "a"
            var dataList = [DiscoverFilterLocation]()
            var numberList = [DiscoverFilterLocation]()

            list
                    .filter { location in
                        switch location {
                        case .location(let location):
                            return location.name != nil
                        case .container(let container):
                            return container.name != nil
                        default: return false
                        }
                    }
                    .sorted { left, right in
                        switch (left, right) {
                        case let (.location(left), .container(right)):
                            return left.name! < right.name!
                        case let (.container(left), .location(right)):
                            return left.name! < right.name!
                        case let (.container(left), .container(right)):
                            return left.name! < right.name!
                        case let (.location(left), .location(right)):
                            return left.name! < right.name!
                        default: return true
                        }
                    }.forEach { containerLocation in
                        switch containerLocation {
                        case .container(let container):
                            let firstLetter = container.name!.lowercased()[container.name!.lowercased().startIndex]
                            if !alpha.contains(firstLetter) {
                                numberList.append(containerLocation)
                            } else if letter == firstLetter {
                                dataList.append(containerLocation)
                            } else {
                                self.results.append((String(letter).uppercased(), dataList))
                                letter = firstLetter
                                dataList = [containerLocation]
                            }

                        case .location(let location):
                            let firstLetter = location.name!.lowercased()[location.name!.lowercased().startIndex]

                            if !alpha.contains(firstLetter) {
                                numberList.append(containerLocation)
                            } else if letter == firstLetter {
                                dataList.append(containerLocation)
                            } else {
                                self.results.append((String(letter).uppercased(), dataList))
                                letter = firstLetter
                                dataList = [containerLocation]
                            }

                        default: return
                        }
                    }

            self.results.append((String(letter).uppercased(), dataList))
            self.results.append(("#", dataList))
            self.tableView.reloadData()
        }
    }

    @objc func textFieldDidChange(_ sender: Any) {
        self.searchResults = []
        self.tableView.reloadData()

        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 0.4)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 2 {
            self.searchResults = []
            self.tableView.reloadData()

            MunchApi.discover.filter.locations.search(text: text) { meta, results in
                if meta.isOk() {
                    self.searchResults = []
                    for result in results {
                        if let container = result as? Container {
                            self.searchResults?.append(DiscoverFilterLocation.container(container))
                        } else if let location = result as? Location {
                            self.searchResults?.append(DiscoverFilterLocation.location(location))
                        }
                    }
                    self.tableView.reloadData()
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        } else {
            self.searchResults = nil
            self.tableView.reloadData()
        }
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DiscoverFilterControllerLocation: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(DiscoverFilterCellSmallLocation.self, forCellReuseIdentifier: DiscoverFilterCellSmallLocation.id)
    }

    var items: [(String?, [DiscoverFilterLocation])] {
        if let searchResults = searchResults {
            return [(nil, searchResults)]
        }
        return results
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverFilterCellSmallLocation.id) as! DiscoverFilterCellSmallLocation

        switch items[indexPath.section].1[indexPath.row] {
        case .nearby:
            cell.titleLabel.text = "Nearby"

        case .anywhere:
            cell.titleLabel.text = "Anywhere"

        case .location(let location):
            cell.titleLabel.text = location.name

        case .container(let container):
            cell.titleLabel.text = container.name
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.section].1[indexPath.row] {
        case .nearby:
            onExtensionDismiss(nil, nil)

        case .anywhere(let location):
            onExtensionDismiss(location, nil)

        case .location(let location):
            onExtensionDismiss(location, nil)

        case .container(let container):
            onExtensionDismiss(nil, container)
        }

        navigationController?.popViewController(animated: true)
    }
}

fileprivate class DiscoverFilterLocationHeaderView: UIView {
    fileprivate var controller: DiscoverFilterController!
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()
    fileprivate let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

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

        textField.placeholder = "Search e.g. Italian in Marina Bay"
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        return textField
    }()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(titleLabel)
        self.addSubview(backButton)
        self.addSubview(textField)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.equalTo(self)
            make.width.equalTo(64)
            make.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.height.equalTo(44)
            make.centerX.equalTo(self)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).inset(-2)
            make.bottom.equalTo(self).inset(10)

            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(36)
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