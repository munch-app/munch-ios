//
// Created by Fuxing Loh on 22/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Moya
import RxSwift
import RxCocoa

//enum SearchFilterLocation {
//    case area(Area)
//}
//
//class SearchFilterLocationController: UIViewController {
//    private let onExtensionDismiss: ((Area?) -> Void)
//    private let searchQuery: SearchQuery
//
//    private let disposeBag = DisposeBag()
//
//    fileprivate let headerView = SearchFilterLocationHeaderView()
//    fileprivate let tableView: UITableView = {
//        let tableView = UITableView()
//        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.estimatedRowHeight = 50
//
//        tableView.tableFooterView = UIView(frame: CGRect.zero)
//        tableView.contentInset.bottom = 16
//        tableView.separatorStyle = .none
//
//        tableView.separatorInset.left = 24
//        return tableView
//    }()
//
//
//    private var results: [(String?, [SearchFilterLocation])] = []
//
//    private var areas: [Area] = []
//    private var areasDatabase = AreaDatabase()
//
//    init(searchQuery: SearchQuery, extensionDismiss: @escaping((Area?) -> Void)) {
//        self.onExtensionDismiss = extensionDismiss
//        self.searchQuery = searchQuery
//        super.init(nibName: nil, bundle: nil)
//
//        self.registerCell()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        // Make navigation bar transparent, bar must be hidden
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.view.addSubview(tableView)
//        self.view.addSubview(headerView)
//
//        self.tableView.delegate = self
//        self.tableView.dataSource = self
//
//        self.headerView.snp.makeConstraints { make in
//            make.top.equalTo(self.view)
//            make.left.right.equalTo(self.view)
//        }
//
//        self.tableView.snp.makeConstraints { make in
//            make.left.right.equalTo(self.view)
//            make.top.equalTo(self.headerView.snp.bottom)
//            make.bottom.equalTo(self.view)
//        }
//
//        areasDatabase.list()
//                .subscribe { event in
//                    switch event {
//                    case .success(let areas):
//                        self.areas = areas
//                        self.tableView.reloadData()
//                    case .error(let error):
//                        self.alert(error: error)
//                    }
//                }.disposed(by: disposeBag)
//
//        self.registerActions()
//    }
//
//    private func registerActions() {
//        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
//        let textControl: ControlProperty<String?> = self.headerView.textField.rx.text
//        textControl
//                .debounce(0.3, scheduler: MainScheduler.instance)
//                .flatMapFirst { s -> Observable<[(String?, [SearchFilterLocation])]> in
//                    guard let text = s?.lowercased(), text.count > 2 else {
//                        return Observable.just(self.areas.mapOrdered())
//                    }
//
//                    return Observable.just(self.areas.search(text: text).mapOrdered())
//                }
//                .subscribe { event in
//                    switch event {
//                    case .next(let results):
//                        self.results = results
//                        self.tableView.reloadData()
//                    case .error(let error):
//                        self.alert(error: error)
//                    case .completed: return
//                    }
//                }
//                .disposed(by: disposeBag)
//
//        self.headerView.textField.text = nil
//    }
//
//    @objc func onBackButton(_ sender: Any) {
//        navigationController?.popViewController(animated: true)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//extension Array where Element == Area {
//    fileprivate static let alpha: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "v", "x", "y", "z"]
//
//    func search(text: String) -> [Area] {
//        return self.filter { area in
//            area.name.lowercased().contains(text.lowercased())
//        }
//    }
//
//    func mapOrdered() -> [(String?, [SearchFilterLocation])] {
//        var letter: Character = "a"
//
//        var results = [(String?, [SearchFilterLocation])]()
//        var dataList = [SearchFilterLocation]()
//        var numberList = [SearchFilterLocation]()
//
//        self.sorted { left, right in
//            return left.name < right.name
//        }.forEach { area in
//            let firstLetter = area.name.lowercased()[area.name.lowercased().startIndex]
//            if !Array.alpha.contains(firstLetter) {
//                numberList.append(.area(area))
//            } else if letter == firstLetter {
//                dataList.append(.area(area))
//            } else {
//                results.append((String(letter).uppercased(), dataList))
//                letter = firstLetter
//                dataList = [.area(area)]
//            }
//        }
//
//        results.append((String(letter).uppercased(), dataList))
//        results.append(("#", dataList))
//        return results
//    }
//}
//
//extension SearchFilterLocationController: UITableViewDataSource, UITableViewDelegate {
//    func registerCell() {
//        tableView.register(FilterLocationCell.self, forCellReuseIdentifier: String(describing: FilterLocationCell.self))
//    }
//
//    var items: [(String?, [SearchFilterLocation])] {
//        return results
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return items.count
//    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return items[section].0
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return items[section].1.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FilterLocationCell.self)) as! FilterLocationCell
//
//        switch items[indexPath.section].1[indexPath.row] {
//        case .area(let area):
//            cell.titleLabel.text = area.name
//        }
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        switch items[indexPath.section].1[indexPath.row] {
//        case .area(let area):
//            onExtensionDismiss(area)
//        }
//
//        navigationController?.popViewController(animated: true)
//    }
//
//    class FilterLocationCell: UITableViewCell {
//
//        let titleLabel: UILabel = {
//            let titleLabel = UILabel()
//            titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
//            titleLabel.textColor = .black
//            return titleLabel
//        }()
//
//        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//            super.init(style: style, reuseIdentifier: reuseIdentifier)
//            self.selectionStyle = .none
//            self.addSubview(titleLabel)
//
//            titleLabel.snp.makeConstraints { (make) in
//                make.top.bottom.equalTo(self).inset(10)
//                make.left.equalTo(self).inset(24)
//                make.right.equalTo(self).inset(24)
//            }
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//    }
//}
//
//fileprivate class SearchFilterLocationHeaderView: UIView {
//    fileprivate var controller: SearchFilterLocationController!
//    fileprivate let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Location".localized()
//        label.font = .systemFont(ofSize: 16, weight: .medium)
//        label.textColor = UIColor.black.withAlphaComponent(0.75)
//        return label
//    }()
//    fileprivate let backButton: UIButton = {
//        let button = UIButton()
//        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
//        button.tintColor = .black
//        button.imageEdgeInsets.left = 18
//        button.contentHorizontalAlignment = .left
//        return button
//    }()
//
//    fileprivate let textField: SearchTextField = {
//        let textField = SearchTextField()
//        textField.clearButtonMode = .whileEditing
//        textField.autocapitalizationType = .none
//        textField.autocorrectionType = .no
//        textField.returnKeyType = .search
//
//        textField.layer.cornerRadius = 4
//        textField.color = UIColor(hex: "2E2E2E")
//        textField.backgroundColor = UIColor.init(hex: "EBEBEB")
//
//        textField.leftImage = UIImage(named: "SC-Search-18")
//        textField.leftImagePadding = 3
//        textField.leftImageWidth = 32
//        textField.leftImageSize = 18
//
//        textField.placeholder = "Search Locations".localized()
//        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
//        return textField
//    }()
//
//    override init(frame: CGRect = CGRect()) {
//        super.init(frame: frame)
//        self.backgroundColor = .white
//
//        self.addSubview(titleLabel)
//        self.addSubview(backButton)
//        self.addSubview(textField)
//
//        backButton.snp.makeConstraints { make in
//            make.top.equalTo(self.safeArea.top)
//            make.left.equalTo(self)
//            make.width.equalTo(64)
//            make.height.equalTo(44)
//        }
//
//        titleLabel.snp.makeConstraints { make in
//            make.top.equalTo(self.safeArea.top)
//            make.height.equalTo(44)
//            make.centerX.equalTo(self)
//        }
//
//        textField.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).inset(-2)
//            make.bottom.equalTo(self).inset(10)
//
//            make.left.right.equalTo(self).inset(24)
//            make.height.equalTo(36)
//        }
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.shadow(vertical: 2)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}