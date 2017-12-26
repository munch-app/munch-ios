//
//  SearchControllerFilter.swift
//  Munch
//
//  Created by Fuxing Loh on 18/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import TTGTagCollectionView
import SnapKit
import BEMCheckBox
import TPKeyboardAvoiding

class SearchFilterController: UIViewController {
    var searchQuery: SearchQuery!

    fileprivate let headerView = SearchFilterHeaderView()
    fileprivate let tableView: TPKeyboardAvoidingTableView = {
        let tableView = TPKeyboardAvoidingTableView()
        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        return tableView
    }()
    fileprivate let applyView = SearchFilterApplyView()

    fileprivate var filterManager: SearchFilterManager!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.filterManager = SearchFilterManager(searchQuery: searchQuery)
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.filterManager = SearchFilterManager(searchQuery: searchQuery)
        self.initViews()
        self.registerCell()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(applyView)

        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.separatorStyle = .none
        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.applyView.snp.top)
        }

        applyView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
        }
    }

    @objc func actionReset(_ sender: Any) {
        searchQuery?.filter.tag.positives = []
        searchQuery?.filter.hour.day = nil
        searchQuery?.filter.hour.time = nil
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        performSegue(withIdentifier: "unwindToSearchWithSegue", sender: self)
    }
}

extension SearchFilterController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchFilterTagCell.self, forCellReuseIdentifier: SearchFilterTagCell.id)
        tableView.register(SearchFilterTagMoreCell.self, forCellReuseIdentifier: SearchFilterTagMoreCell.id)
        tableView.register(SearchFilterLocationCell.self, forCellReuseIdentifier: SearchFilterLocationCell.id)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return filterManager.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterManager.items[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filterManager.items[section].0
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = .white
        header.textLabel!.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.75)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = filterManager.items[indexPath.section].1[indexPath.row]
        let selectedTags = self.searchQuery.filter.tag.positives

        switch item {
        case .location:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterLocationCell.id) as! SearchFilterLocationCell
            cell.controller = self
            return cell
        case let .tag(tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagCell.id) as! SearchFilterTagCell
            cell.render(title: tag, selected: selectedTags.contains(tag))
            return cell
        case let .seeMore(name):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagMoreCell.id) as! SearchFilterTagMoreCell
            cell.render(text: "More \(name)")
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filterManager.items[indexPath.section].1[indexPath.row]

        switch item {
        case let .tag(tag):
            if let cell = tableView.cellForRow(at: indexPath) as? SearchFilterTagCell {
                tableView.beginUpdates()
                if (cell.flip()) {
                    self.searchQuery.filter.tag.positives.insert(tag)
                } else {
                    self.searchQuery.filter.tag.positives.remove(tag)
                }
                tableView.endUpdates()
                self.applyView.render(searchQuery: searchQuery)
            }
        case let .seeMore(type):
            let controller = SearchFilterMoreController(searchQuery: searchQuery, type: type)
            self.navigationController?.pushViewController(controller, animated: true)
        default:
            return
        }
    }
}

fileprivate class SearchFilterHeaderView: UIView {
    fileprivate let resetButton = UIButton()
    fileprivate let titleView = UILabel()
    fileprivate let cancelButton = UIButton()

    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(resetButton)
        self.addSubview(titleView)
        self.addSubview(cancelButton)

        self.makeViews()
    }

    private func makeViews() {
        self.backgroundColor = .white

        resetButton.setTitle("RESET", for: .normal)
        resetButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        resetButton.titleEdgeInsets.left = 24
        resetButton.contentHorizontalAlignment = .left
        resetButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.width.equalTo(90)
            make.left.equalTo(self)
        }

        titleView.text = "Filters"
        titleView.font = .systemFont(ofSize: 17, weight: .medium)
        titleView.textAlignment = .center
        titleView.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.height.equalTo(44)
            make.bottom.equalTo(self)
            make.left.equalTo(resetButton.snp.right)
            make.right.equalTo(cancelButton.snp.left)
        }

        cancelButton.setTitle("CANCEL", for: .normal)
        cancelButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cancelButton.titleEdgeInsets.right = 24
        cancelButton.contentHorizontalAlignment = .right
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)
            make.width.equalTo(90)
            make.right.equalTo(self)
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

fileprivate class SearchFilterApplyView: UIView {
    fileprivate let applyBtn = UIButton()
    fileprivate var searchQuery: SearchQuery!

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        initViews()
    }

    private func initViews() {
        self.backgroundColor = UIColor.white
        self.addSubview(applyBtn)

        applyBtn.layer.cornerRadius = 3
        applyBtn.backgroundColor = .primary
        applyBtn.setTitle("Loading...", for: .normal)
        applyBtn.setTitleColor(.white, for: .normal)
        applyBtn.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        applyBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }
    }

    func render(searchQuery: SearchQuery) {
        self.searchQuery = searchQuery
        applyBtn.setTitle("Loading...", for: .normal)
        self.perform(#selector(renderDidCommit(_:)), with: nil, afterDelay: 0.5)
    }

    @objc fileprivate func renderDidCommit(_ sender: Any) {
        MunchApi.search.count(query: searchQuery, callback: { (meta, count) in
            if let count = count {
                if count == 0 {
                    self.applyBtn.setTitle("No result", for: .normal)
                } else if count > 100 {
                    self.applyBtn.setTitle("See 100+ places", for: .normal)
                } else if count <= 10 {
                    self.applyBtn.setTitle("See \(count) places", for: .normal)
                } else {
                    let rounded = count / 10 * 10
                    self.applyBtn.setTitle("See \(rounded)+ places", for: .normal)
                }
            }
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchFilterLocationCell: UITableViewCell {
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()
    private let moreButton: UIButton = {
        let button = UIButton()
        button.tintColor = .black
        button.setImage(UIImage(named: "Search-Right-Arrow"), for: .normal)

        button.setTitle("MORE", for: .normal)
        button.setTitleColor(UIColor.black.withAlphaComponent(0.85), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        button.contentEdgeInsets.right = 20
        button.titleEdgeInsets.right = -2

        button.contentHorizontalAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 100, height: 90)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchFilterLocationGridCell.self, forCellWithReuseIdentifier: "SearchFilterLocationGridCell")
        return collectionView
    }()

    var controller: SearchFilterController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(moreButton)
        self.addSubview(headerLabel)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        moreButton.snp.makeConstraints { make in
            make.right.equalTo(self)
            make.width.equalTo(80)
            make.top.bottom.equalTo(headerLabel)
        }

        headerLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(24)
            make.right.equalTo(moreButton.snp.left)
            make.top.equalTo(self).inset(12)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(headerLabel.snp.bottom).inset(-12)
            make.bottom.equalTo(self).inset(10)
            make.height.equalTo(100)
        }
    }

    func actionMore(_ sender: Any) {

        // TODO
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchFilterLocationCell"
    }
}

extension SearchFilterLocationCell: UICollectionViewDataSource, UICollectionViewDelegate {
    private var items: [LocationType] {
        return [LocationType.nearby, LocationType.anywhere] + controller.filterManager.recentLocations
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let locationType = items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchFilterLocationGridCell", for: indexPath) as! SearchFilterLocationGridCell

        switch locationType {
        case .nearby:
            cell.render(text: "Nearby", image: UIImage(named: "Search-Location-Nearby"))
        case .anywhere:
            cell.render(text: "Anywhere", image: UIImage(named: "Search-Location-Anywhere"))
        case let .recentLocation(location):
            cell.render(text: location.name, image: UIImage(named: "Search-Location-Recent"))
        case let .recentContainer(container):
            cell.render(text: container.name, image: UIImage(named: "Search-Location-Recent"))
        case let .location(location):
            cell.render(text: location.name, image: nil)
        case let .container(container):
            cell.render(text: container.name, image: nil)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let locationType = items[indexPath.row]
        controller.searchQuery.filter.location = nil
        controller.searchQuery.filter.containers = nil

        switch locationType {
        case .nearby:
            break
        case .anywhere:
            controller.searchQuery.filter.location = SearchFilterManager.anywhere
        case let .recentLocation(location):
            controller.searchQuery.filter.location = location
        case let .recentContainer(container):
            controller.searchQuery.filter.containers = [container]
        case let .location(location):
            controller.searchQuery.filter.location = location
        case let .container(container):
            controller.searchQuery.filter.containers = [container]
        }
        controller.actionApply(collectionView)
    }
}

fileprivate class SearchFilterLocationGridCell: UICollectionViewCell {
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F8F8F8")
        return view
    }()
    let imageView: MunchImageView = {
        let imageView = MunchImageView()
        imageView.tintColor = UIColor(hex: "333333")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let nameLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.backgroundColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)

        nameLabel.textContainer.maximumNumberOfLines = 1
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 6, leftRight: 4)
        nameLabel.isUserInteractionEnabled = false
        return nameLabel
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)

        imageView.snp.makeConstraints { make in
            make.left.right.equalTo(containerView).inset(35)
            make.top.equalTo(containerView)
            make.bottom.equalTo(nameLabel.snp.top)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.bottom.equalTo(containerView)
            make.height.equalTo(30)
        }

        containerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        self.layoutIfNeeded()
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.5)
        imageView.roundCorners([.topLeft, .topRight], radius: 3)
        nameLabel.roundCorners([.bottomLeft, .bottomRight], radius: 3)
    }

    func render(text: String?, image: UIImage?) {
        nameLabel.text = text
        imageView.image = image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchFilterTagCell: UITableViewCell {
    let titleLabel = UILabel()
    let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 26, height: 26))

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        self.addSubview(checkButton)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        titleLabel.textColor = .black
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(12)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(checkButton.snp.left).inset(-12)
        }

        checkButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(11)
            make.right.equalTo(self).inset(24)
        }
        checkButton.boxType = .square
        checkButton.cornerRadius = 1
        checkButton.lineWidth = 1.5
        checkButton.tintColor = UIColor.black.withAlphaComponent(0.6)
        checkButton.onCheckColor = .primary
        checkButton.onTintColor = .primary
        checkButton.animationDuration = 0.25
        checkButton.isEnabled = false
    }

    func render(title: String, selected: Bool) {
        titleLabel.text = title
        checkButton.setOn(selected, animated: false)
    }

    /**
     Flip the switch on check button
     */
    func flip() -> Bool {
        let flip = !checkButton.on
        checkButton.setOn(flip, animated: true)
        return flip
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchFilterTagCell"
    }
}

fileprivate class SearchFilterTagMoreCell: UITableViewCell {
    let titleLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .primary600
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(12)
            make.left.right.equalTo(self).inset(24)
        }
    }

    func render(text: String) {
        titleLabel.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchFilterTagMoreCell"
    }
}

fileprivate class SearchFilterMoreController: UIViewController, UIGestureRecognizerDelegate {
    var searchQuery: SearchQuery
    let type: String
    let tags: [String]

    let headerView = SearchFilterMoreHeaderView()
    let tableView = UITableView()
    let applyView = SearchFilterMoreApplyView()

    init(searchQuery: SearchQuery, type: String) {
        self.searchQuery = searchQuery
        self.type = type
        self.tags = SearchFilterManager(searchQuery: searchQuery).getMoreTypes(type: type)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
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
        self.initViews()
        self.registerCell()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.applyView.render(searchQuery: searchQuery)
        self.headerView.titleView.text = type
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)
        self.view.addSubview(applyView)

        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
        }

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.equalTo(self.applyView.snp.top)
        }

        applyView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
        }
    }

    @objc func actionReset(_ sender: Any) {
        for tag in tags {
            searchQuery.filter.tag.positives.remove(tag)
        }
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        // On cancel, update previous filter view
        if let count = navigationController?.viewControllers.count,
           let filter = navigationController?.viewControllers[count - 2] as? SearchFilterController {
            filter.searchQuery = self.searchQuery
        }
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    fileprivate class SearchFilterMoreHeaderView: UIView {
        fileprivate let resetButton = UIButton()
        fileprivate let titleView = UILabel()
        fileprivate let cancelButton = UIButton()

        init() {
            super.init(frame: CGRect.zero)
            self.addSubview(resetButton)
            self.addSubview(titleView)
            self.addSubview(cancelButton)

            self.makeViews()
        }

        private func makeViews() {
            self.backgroundColor = .white

            resetButton.setTitle("RESET", for: .normal)
            resetButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
            resetButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            resetButton.titleEdgeInsets.left = 24
            resetButton.contentHorizontalAlignment = .left
            resetButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.width.equalTo(90)
                make.left.equalTo(self)
            }

            titleView.font = .systemFont(ofSize: 17, weight: .medium)
            titleView.textAlignment = .center
            titleView.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.height.equalTo(44)
                make.bottom.equalTo(self)
                make.left.equalTo(resetButton.snp.right)
                make.right.equalTo(cancelButton.snp.left)
            }

            cancelButton.setTitle("CANCEL", for: .normal)
            cancelButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
            cancelButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            cancelButton.titleEdgeInsets.right = 24
            cancelButton.contentHorizontalAlignment = .right
            cancelButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.width.equalTo(90)
                make.right.equalTo(self)
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

    fileprivate class SearchFilterMoreApplyView: SearchFilterApplyView {
        fileprivate override func renderDidCommit(_ sender: Any) {
            MunchApi.search.count(query: searchQuery, callback: { (meta, count) in
                if let count = count {
                    if count == 0 {
                        self.applyBtn.setTitle("No result", for: .normal)
                    } else if count > 100 {
                        self.applyBtn.setTitle("Apply (100+ places)", for: .normal)
                    } else if count <= 10 {
                        self.applyBtn.setTitle("Apply (\(count) places)", for: .normal)
                    } else {
                        let rounded = count % 10 * 10
                        self.applyBtn.setTitle("Apply (\(rounded)+ places)", for: .normal)
                    }
                }
            })
        }
    }
}

extension SearchFilterMoreController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchFilterTagCell.self, forCellReuseIdentifier: SearchFilterTagCell.id)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedTags = self.searchQuery.filter.tag.positives
        let tag = tags[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagCell.id) as! SearchFilterTagCell
        cell.render(title: tag, selected: selectedTags.contains(tag))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tag = tags[indexPath.row]

        if let cell = tableView.cellForRow(at: indexPath) as? SearchFilterTagCell {
            tableView.beginUpdates()
            if (cell.flip()) {
                self.searchQuery.filter.tag.positives.insert(tag)
            } else {
                self.searchQuery.filter.tag.positives.remove(tag)
            }
            tableView.endUpdates()
            self.applyView.render(searchQuery: searchQuery)
        }
    }
}