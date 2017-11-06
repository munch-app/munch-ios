//
// Created by Fuxing Loh on 5/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchLocationController: UIViewController {
    var searchQuery: SearchQuery!
    let headerView = SearchLocationHeaderView()
    let tableView = UITableView()

    var results: [Location]?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        self.headerView.textField.becomeFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
        if let text = textField.text, text.count >= 3 {
            MunchApi.locations.suggest(text: text, callback: { (meta, locations) in
                self.results = locations
                self.tableView.reloadData()
            })
        } else {
            results = nil
            self.tableView.reloadData()
        }
    }
}

extension SearchLocationController: UITableViewDataSource, UITableViewDelegate {
    var items: [Any] {
        if let results = results {
            return results
        }

        // TODO Popular Locations
        // TODO History
        return []
    }

    func registerCell() {
        tableView.register(SearchLocationNearbyCell.self, forCellReuseIdentifier: SearchLocationNearbyCell.id)
        tableView.register(SearchLocationCell.self, forCellReuseIdentifier: SearchLocationCell.id)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if results != nil {
            return "SUGGESTIONS"
        }
        return "RECENT SEARCH"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = UIColor(hex: "F1F1F1")
        header.textLabel!.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchLocationCell.id) as! SearchLocationCell
        let item = items[indexPath.row]

        if let location = item as? Location {
            cell.render(title: location.name)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        if let location = item as? Location {
            self.searchQuery.location = location
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        }
    }
}

class SearchLocationHeaderView: UIView {
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
        self.snp.makeConstraints { make in
            make.height.equalTo(55)
        }

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

        textField.snp.makeConstraints { make in
            make.top.equalTo(self).inset(8)
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
            make.top.equalTo(self).inset(8)
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

class SearchLocationNearbyCell: UITableViewCell {
    let button = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor(hex: "F1F1F1")

        button.isEnabled = false
        button.backgroundColor = .white
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center

        // Setup Image
        button.setImage(UIImage(named: "SC-Define Location-30"), for: .normal)
        button.imageEdgeInsets.left = 10
        button.imageEdgeInsets.right = 10
        button.tintColor = UIColor.secondary

        // Setup Text
        button.setTitle("Detect my current location", for: .normal)
        button.setTitleColor(UIColor.secondary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        button.titleEdgeInsets.left = 20

        // Set Button Layer
        button.layer.cornerRadius = 4.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.secondary.cgColor
        self.addSubview(button)

        button.snp.makeConstraints { make in
            make.height.equalTo(38)
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(14)
            make.bottom.equalTo(self).inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchLocationNearbyCell"
    }
}

class SearchLocationCell: UITableViewCell {
    let titleLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(11)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(title: String?) {
        self.titleLabel.text = title
    }

    class var id: String {
        return "SearchLocationCell"
    }
}