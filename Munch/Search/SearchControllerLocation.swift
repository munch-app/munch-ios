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
    var searchQuery: SearchQuery!
    let headerView = SearchLocationHeaderView()
    let tableView = TPKeyboardAvoidingTableView()

    let recentDatabase = RecentDatabase(name: "SearchLocation", maxItems: 3)

    var results: [LocationType]?
    var recentLocations: [LocationType]!
    var popularLocations: [LocationType]!

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
        self.initViews()

        self.popularLocations = readJson(forResource: "locations-popular")?.flatMap({ Location(json: $0.1) }).map({ LocationType.location($0) })
        self.recentLocations = recentDatabase.get().flatMap({ $1 }).flatMap({ Location(json: $0) }).map({ LocationType.recent($0) })

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
        if let text = textField.text, text.count >= 2 {
            MunchApi.locations.suggest(text: text, callback: { (meta, locations) in
                self.results = locations.map({ LocationType.location($0) })
                self.tableView.reloadData()
            })
        } else {
            results = nil
            self.tableView.reloadData()
        }
    }

    private func readJson(forResource resourceName: String) -> JSON? {
        if let path = Bundle.main.path(forResource: resourceName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                return try JSON(data: data)
            } catch let error {
                print("parse error: \(error.localizedDescription)")
            }
        }

        print("Invalid json file/filename/path.")
        return nil
    }
}

extension SearchLocationController: UITableViewDataSource, UITableViewDelegate {
    enum LocationType {
        case nearby
        case singapore
        case recent(Location)
        case location(Location)
    }

    private var items: [(String?, [LocationType])] {
        if let results = results {
            return [("SUGGESTIONS", results)]
        } else {
            return [
                (nil, [LocationType.nearby, LocationType.singapore] + recentLocations),
                ("POPULAR LOCATIONS", popularLocations ?? []),
            ]
        }
    }

    private func registerCell() {
        tableView.register(SearchLocationNearbyCell.self, forCellReuseIdentifier: SearchLocationNearbyCell.id)
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
        let item = items[indexPath.section].1[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchLocationCell.id) as! SearchLocationCell

        switch item {
        case .nearby:
            cell.render(title: "Nearby")
        case .singapore:
            cell.render(title: "Singapore")
        case let .location(location):
            cell.render(title: location.name)
        case let .recent(location):
            cell.render(title: location.name, type: "RECENT")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case .nearby:
            self.searchQuery.location = nil
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        case .singapore:
            var singapore = Location()
            singapore.name = "Singapore"
            singapore.country = "singapore"
            singapore.city = "singapore"
            singapore.latLng = "1.290270, 103.851959"
            singapore.points = ["1.26675774823,103.603134155", "1.32442122318,103.617553711", "1.38963424766,103.653259277", "1.41434608581,103.666305542", "1.42944763543,103.671798706", "1.43905766081,103.682785034", "1.44386265833,103.695831299", "1.45896401284,103.720550537", "1.45827758983,103.737716675", "1.44935407163,103.754196167", "1.45004049736,103.760375977", "1.47887018872,103.803634644", "1.4754381021,103.826980591", "1.45827758983,103.86680603", "1.43219336108,103.892211914", "1.4287612035,103.897018433", "1.42670190649,103.915557861", "1.43219336108,103.934783936", "1.42189687297,103.960189819", "1.42464260763,103.985595703", "1.42121043879,104.000701904", "1.43974408965,104.02130127", "1.44592193988,104.043960571", "1.42464260763,104.087219238", "1.39718511473,104.094772339", "1.35737118164,104.081039429", "1.29009788407,104.127044678", "1.277741368,104.127044678", "1.25371463932,103.982162476", "1.17545464492,103.812561035", "1.13014521522,103.736343384", "1.19055762617,103.653945923", "1.1960495989,103.565368652", "1.26675774823,103.603134155"]
            self.searchQuery.location = singapore
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        case let .location(location):
            if let name = location.name {
                recentDatabase.put(text: name, dictionary: location.toParams())
            }
            self.searchQuery.location = location
            self.performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
        case let .recent(location):
            if let name = location.name {
                recentDatabase.put(text: name, dictionary: location.toParams())
            }
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
    let typeLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        self.addSubview(typeLabel)

        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(16)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(typeLabel.snp.left).inset(8)
        }

        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        typeLabel.textColor = UIColor(hex: "686868")
        typeLabel.textAlignment = .right
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
