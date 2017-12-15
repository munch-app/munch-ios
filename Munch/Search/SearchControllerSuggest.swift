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

class SearchSuggestController: UIViewController {
    var searchQuery: SearchQuery!
    let headerView = SearchSuggestHeaderView()
    let tableView = TPKeyboardAvoidingTableView()

    let recentDatabase = RecentDatabase(name: "SearchSuggest", maxItems: 10)

    var suggestResults: [SuggestType]?
    var recentSearches: [SuggestType]?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        if suggestResults == nil {
            self.headerView.textField.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if suggestResults != nil {
            self.headerView.textField.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.headerView.textField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.recentSearches = self.map(results: recentDatabase.get()
                .flatMap({ $1 }).flatMap({ SearchClient.parseResult(result: $0) }))

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.textField.text = self.searchQuery.query
        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.headerView.textField.addTarget(self, action: #selector(textFieldShouldReturn(_:)), for: .editingDidEndOnExit)
        registerCell()
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(self.view).inset(20)
            make.left.right.equalTo(self.view)
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.contentInset.top = 0
        self.tableView.contentInset.bottom = 12
        self.tableView.separatorInset.left = 24
        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @objc func textFieldDidChange(_ sender: Any) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(textFieldDidCommit(textField:)), with: headerView.textField, afterDelay: 0.3)
    }

    @objc func textFieldDidCommit(textField: UITextField) {
        if let text = textField.text, text.count >= 2 {
            MunchApi.search.suggest(text: text, size: 20, callback: { (meta, results) in
                self.suggestResults = self.map(results: results)
                self.tableView.reloadData()
            })
        } else {
            suggestResults = nil
            self.tableView.reloadData()
        }
    }

    @objc func textFieldShouldReturn(_ sender: Any) -> Bool {
        if let text = headerView.textField.text {
            self.searchQuery.query = text
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        }
        return true
    }

    private func map(results: [SearchResult]) -> [SuggestType] {
        return results.flatMap({
            if let place = $0 as? Place {
                return SuggestType.place(place)
            } else if let location = $0 as? Location {
                return SuggestType.location(location)
            } else if let tag = $0 as? Tag {
                return SuggestType.tag(tag)
            } else if let container = $0 as? Container {
                return SuggestType.container(container)
            } else {
                return nil
            }
        })
    }
}

extension SearchSuggestController: UITableViewDataSource, UITableViewDelegate {
    enum SuggestType {
        case place(Place)
        case tag(Tag)
        case location(Location)
        case container(Container)
    }

    private var items: [(String?, [SuggestType])] {
        if let results = suggestResults {
            return [("SUGGESTIONS", results)]
        } else {
            return [("RECENT SEARCH", recentSearches ?? [])]
        }
    }

    func registerCell() {
        tableView.register(SearchQueryCell.self, forCellReuseIdentifier: SearchQueryCell.id)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchQueryCell.id) as! SearchQueryCell
        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case let .place(place):
            cell.render(title: place.name, type: "PLACE")
        case let .location(location):
            cell.render(title: location.name, type: "LOCATION")
        case let .tag(tag):
            cell.render(title: tag.name, type: "TAG")
        case let .container(container):
            cell.render(title: container.name, type: container.type?.uppercased())
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case let .place(place):
            if let placeId = place.id {
                recentDatabase.put(text: placeId, dictionary: place.toParams())
                let controller = PlaceViewController(placeId: placeId)
                self.navigationController!.pushViewController(controller, animated: true)
            }
        case let .location(location):
            recentDatabase.put(text: location.id ?? "", dictionary: location.toParams())
            self.searchQuery.filter.location = location
            self.searchQuery.filter.containers = []
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        case let .tag(tag):
            if let tagName = tag.name {
                recentDatabase.put(text: tag.id ?? "", dictionary: tag.toParams())
                self.searchQuery.filter.tag.positives.insert(tagName)
                self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
            }
        case let .container(container):
            recentDatabase.put(text: container.id ?? "", dictionary: container.toParams())
            self.searchQuery.filter.location = nil
            self.searchQuery.filter.containers = [container]
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        }
    }
}

class SearchSuggestHeaderView: UIView {
    fileprivate let textField = SearchTextField()
    fileprivate let cancelButton = UIButton()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(textField)
        self.addSubview(cancelButton)

        self.makeViews()
    }

    private func makeViews() {
        self.backgroundColor = .white

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

        textField.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top).inset(8)
            make.bottom.equalTo(self).inset(11)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(cancelButton.snp.left)
            make.height.equalTo(36)
        }

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.titleEdgeInsets.right = 24
        cancelButton.contentHorizontalAlignment = .right
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

class SearchQueryCell: UITableViewCell {
    let titleLabel = UILabel()
    let typeLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        self.addSubview(typeLabel)

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(16).priority(999)
            make.left.equalTo(self).inset(24).priority(999)
            make.right.equalTo(typeLabel.snp.left).inset(-8).priority(999)
        }

        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        typeLabel.textColor = UIColor(hex: "686868")
        typeLabel.textAlignment = .right
        typeLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(16)
            make.right.equalTo(self).inset(24)
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
        return "SearchSuggestCell"
    }
}
