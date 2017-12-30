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
import RangeSeekSlider

class SearchFilterRootController: UINavigationController, UINavigationControllerDelegate {
    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [SearchFilterController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)]
        self.delegate = self
    }

    init(startWithLocation searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        let filterController = SearchFilterController(searchQuery: searchQuery, extensionDismiss: extensionDismiss)
        let locationController = SearchLocationController(searchQuery: searchQuery) { searchQuery in
            if let searchQuery = searchQuery {
                filterController.render(searchQuery: searchQuery)
            }
        }

        self.viewControllers = [filterController, locationController]
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

class SearchFilterController: UIViewController {
    fileprivate var filterManager: SearchFilterManager
    fileprivate var items: [(String?, [FilterType])]!
    private let onExtensionDismiss: ((SearchQuery?) -> Void)

    private let headerView = SearchFilterHeaderView()
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

    init(searchQuery: SearchQuery, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.filterManager = SearchFilterManager(searchQuery: searchQuery)
        self.onExtensionDismiss = extensionDismiss
        super.init(nibName: nil, bundle: nil)

        self.initViews()
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

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.render(searchQuery: filterManager.searchQuery)
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

    func render(searchQuery: SearchQuery) {
        self.filterManager = .init(searchQuery: searchQuery)
        self.items = filterManager.items
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    @objc func actionReset(_ sender: Any) {
        self.applyView.render(searchQuery: filterManager.reset())
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.dismiss(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(filterManager.searchQuery)
        self.dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchFilterController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(SearchFilterTagCell.self, forCellReuseIdentifier: SearchFilterTagCell.id)
        tableView.register(SearchFilterTagMoreCell.self, forCellReuseIdentifier: SearchFilterTagMoreCell.id)
        tableView.register(SearchFilterLocationCell.self, forCellReuseIdentifier: SearchFilterLocationCell.id)
        tableView.register(SearchFilterHourCell.self, forCellReuseIdentifier: SearchFilterHourCell.id)
        tableView.register(SearchFilterPriceCell.self, forCellReuseIdentifier: SearchFilterPriceCell.id)
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
        header.tintColor = .white
        header.textLabel!.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.75)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO Render selected data on Location, Hour, Price on call?

        switch items[indexPath.section].1[indexPath.row] {
        case .location:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterLocationCell.id) as! SearchFilterLocationCell
            cell.controller = self
            cell.collectionView.reloadData()
            return cell
        case .hour:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterHourCell.id) as! SearchFilterHourCell
            cell.controller = self
            return cell
        case .price:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterPriceCell.id) as! SearchFilterPriceCell
            cell.controller = self
            return cell
        case let .tag(tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagCell.id) as! SearchFilterTagCell
            cell.render(title: tag, selected: filterManager.isSelected(tag: tag))
            return cell
        case let .seeMore(name):
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagMoreCell.id) as! SearchFilterTagMoreCell
            cell.render(text: "More \(name)")
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.section].1[indexPath.row] {
        case let .tag(tag):
            if let cell = tableView.cellForRow(at: indexPath) as? SearchFilterTagCell {
                let searchQuery = self.filterManager.select(tag: tag, selected: cell.flip())
                self.applyView.render(searchQuery: searchQuery)
            }
        case let .seeMore(type):
            let controller = SearchFilterMoreController(searchQuery: filterManager.searchQuery, type: type) { searchQuery in
                if let searchQuery = searchQuery {
                    self.render(searchQuery: searchQuery)
                }
            }
            self.navigationController?.pushViewController(controller, animated: true)
        default:
            return
        }
    }
}


// MARK: Header & Apply View
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
    fileprivate let applyBtn: UIButton = {
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
        self.addSubview(applyBtn)

        applyBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(12)
            make.bottom.equalTo(self.safeArea.bottom).inset(12)
            make.right.left.equalTo(self).inset(24)
            make.height.equalTo(46)
        }
    }

    func render(searchQuery: SearchQuery) {
        applyBtn.setTitle("Loading...", for: .normal)
        self.searchQuery = searchQuery
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

// MARK: Filter Location Cell
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
    fileprivate let collectionView: UICollectionView = {
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
        self.moreButton.addTarget(self, action: #selector(actionMore(_:)), for: .touchUpInside)

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

    @objc func actionMore(_ sender: Any) {
        let controller = SearchLocationController(searchQuery: self.controller.filterManager.searchQuery) { searchQuery in
            if let searchQuery = searchQuery {
                self.controller.render(searchQuery: searchQuery)
            }
        }
        self.controller.navigationController?.pushViewController(controller, animated: true)
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
        return controller.filterManager.locations
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchFilterLocationGridCell", for: indexPath) as! SearchFilterLocationGridCell

        switch items[indexPath.row] {
        case .nearby:
            let selected = controller.filterManager.isSelected(location: nil)
            cell.render(text: "Nearby", image: UIImage(named: "Search-Location-Nearby"), selected: selected)
        case let .anywhere(location):
            let selected = controller.filterManager.isSelected(location: location)
            cell.render(text: "Anywhere", image: UIImage(named: "Search-Location-Anywhere"), selected: selected)
        case let .recentLocation(location):
            let selected = controller.filterManager.isSelected(location: location)
            cell.render(text: location.name, image: UIImage(named: "Search-Location-Recent"), selected: selected)
        case let .recentContainer(container):
            let selected = controller.filterManager.isSelected(container: container)
            cell.render(text: container.name, image: UIImage(named: "Search-Location-Recent"), selected: selected)
        case let .location(location):
            let selected = controller.filterManager.isSelected(location: location)
            cell.render(text: location.name, image: nil, selected: selected)
        case let .container(container):
            let selected = controller.filterManager.isSelected(container: container)
            cell.render(text: container.name, image: nil, selected: selected)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .nearby:
            controller.filterManager.select(location: nil, save: false)
        case .anywhere:
            controller.filterManager.select(location: SearchFilterManager.anywhere, save: false)
        case let .recentLocation(location):
            controller.filterManager.select(location: location)
        case let .recentContainer(container):
            controller.filterManager.select(container: container)
        case let .location(location):
            controller.filterManager.select(location: location)
        case let .container(container):
            controller.filterManager.select(container: container)
        }
        collectionView.reloadData()
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
            nameLabel.roundCorners([.bottomLeft, .bottomRight], radius: 3.0)
            containerView.layer.cornerRadius = 3.0
            containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.5)
        }

        func render(text: String?, image: UIImage?, selected: Bool) {
            nameLabel.text = text
            imageView.image = image
            containerView.backgroundColor = selected ? .primary020 : UIColor(hex: "F8F8F8")
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: Filter Hour Cell
fileprivate class SearchFilterHourCell: UITableViewCell {
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Timing"
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewLeftAlignedLayout()
        layout.sectionInset = UIEdgeInsets(top: 2, left: 24, bottom: 2, right: 24)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16 // LeftRight
        layout.minimumLineSpacing = 14 // TopBottom
        layout.sectionInset.top = 2

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchFilterHourGridCell.self, forCellWithReuseIdentifier: "SearchFilterHourGridCell")
        return collectionView
    }()

    var controller: SearchFilterController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(headerLabel)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        headerLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(12)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(headerLabel.snp.bottom).inset(-12)
            make.bottom.equalTo(self).inset(10)
            make.height.equalTo(80)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchFilterHourCell"
    }
}

extension SearchFilterHourCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var items: [FilterHourType] {
        return controller.filterManager.hourItems
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchFilterHourGridCell", for: indexPath) as! SearchFilterHourGridCell

        switch items[indexPath.row] {
        case .now:
            cell.render(text: "Open Now", image: UIImage(named: "Search-Timing-Present"))
        case .breakfast:
            cell.render(text: "Breakfast", image: nil)
        case .lunch:
            cell.render(text: "Lunch", image: nil)
        case .dinner:
            cell.render(text: "Dinner", image: nil)
        case .supper:
            cell.render(text: "Supper", image: nil)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch items[indexPath.row] {
        case .now:
            let width = UILabel.textWidth(font: SearchFilterHourGridCell.labelFont, text: "Open Now")
            return CGSize(width: width + 28 + 20, height: 30)
        case .breakfast:
            let width = UILabel.textWidth(font: SearchFilterHourGridCell.labelFont, text: "Breakfast")
            return CGSize(width: width + 28, height: 30)
        case .lunch:
            let width = UILabel.textWidth(font: SearchFilterHourGridCell.labelFont, text: "Lunch")
            return CGSize(width: width + 28, height: 30)
        case .dinner:
            let width = UILabel.textWidth(font: SearchFilterHourGridCell.labelFont, text: "Dinner")
            return CGSize(width: width + 28, height: 30)
        case .supper:
            let width = UILabel.textWidth(font: SearchFilterHourGridCell.labelFont, text: "Supper")
            return CGSize(width: width + 28, height: 30)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .now:
            return
        case .breakfast:
            return
        case .lunch:
            return
        case .dinner:
            return
        case .supper:
            return
        }
//        controller.actionApply(collectionView)
    }

    fileprivate class SearchFilterHourGridCell: UICollectionViewCell {
        static let labelFont = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        let containerView: UIView = {
            let view = UIView()
            view.backgroundColor = .white
            return view
        }()
        let imageView: MunchImageView = {
            let imageView = MunchImageView()
            imageView.tintColor = UIColor(hex: "333333")
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        let nameLabel: UILabel = {
            let nameLabel = UILabel()
            nameLabel.backgroundColor = .white
            nameLabel.font = labelFont
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)

            nameLabel.numberOfLines = 1
            nameLabel.isUserInteractionEnabled = false

            nameLabel.textAlignment = .right
            return nameLabel
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(containerView)
            containerView.addSubview(nameLabel)
            containerView.addSubview(imageView)

            nameLabel.snp.makeConstraints { make in
                make.right.equalTo(containerView).inset(14)
                make.left.top.bottom.equalTo(containerView)
                make.height.equalTo(30)
            }

            imageView.snp.makeConstraints { make in
                make.top.bottom.equalTo(containerView).inset(5)
                make.left.equalTo(containerView).inset(8)
                make.width.equalTo(20)
            }

            containerView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }
            self.layoutIfNeeded()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            containerView.layer.cornerRadius = 2.0
            containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.5)
        }

        func render(text: String?, image: UIImage?) {
            nameLabel.text = text
            imageView.image = image
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: Filter Price Cell
fileprivate class SearchFilterPriceCell: UITableViewCell {
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Price Range"
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()
    private let averageLabel: UILabel = {
        let label = UILabel()
        label.text = "Average price in area is $25"
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.black.withAlphaComponent(0.75)
        return label
    }()

    private let priceButtons = PriceButtonGroup()
    private let priceSlider = PriceRangeSlider()

    var controller: SearchFilterController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(priceSlider)
        self.addSubview(headerLabel)
        self.addSubview(averageLabel)
        self.addSubview(priceButtons)


        headerLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(12)
        }

        averageLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(headerLabel.snp.bottom).inset(-10)
            make.bottom.equalTo(priceSlider.snp.top).inset(-12)
        }

        priceSlider.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(16).priority(999)
            make.bottom.equalTo(priceButtons.snp.top).inset(8).priority(999)
        }

        priceButtons.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(self).inset(12)
        }

        self.layoutIfNeeded()
    }

    class var id: String {
        return "SearchFilterPriceCell"
    }

    class PriceRangeSlider: RangeSeekSlider {
        override func setupStyle() {
            colorBetweenHandles = .primary
            handleColor = .primary
            tintColor = UIColor(hex: "BBBBBB")
            minLabelColor = UIColor.black.withAlphaComponent(0.75)
            maxLabelColor = UIColor.black.withAlphaComponent(0.75)
            minLabelFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            maxLabelFont = UIFont.systemFont(ofSize: 14, weight: .regular)

            numberFormatter.numberStyle = .currency

            handleDiameter = 18
            selectedHandleDiameterMultiplier = 1.3
            lineHeight = 3.0
        }
    }

    class PriceButtonGroup: UIButton {
        fileprivate let cheapButton: UIButton = {
            let button = UIButton()
            button.backgroundColor = .white
            button.setTitle("$", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
            return button
        }()
        fileprivate let averageButton: UIButton = {
            let button = UIButton()
            button.backgroundColor = .white
            button.setTitle("$$", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
            return button
        }()
        fileprivate let expensiveButton: UIButton = {
            let button = UIButton()
            button.backgroundColor = .white
            button.setTitle("$$$", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
            return button
        }()

        required init() {
            super.init(frame: .zero)
            self.addSubview(cheapButton)
            self.addSubview(averageButton)
            self.addSubview(expensiveButton)

            cheapButton.snp.makeConstraints { make in
                make.left.equalTo(self)
                make.right.equalTo(averageButton.snp.left).inset(-18)
                make.width.equalTo(averageButton.snp.width)
                make.width.equalTo(expensiveButton.snp.width)
                make.height.equalTo(28)
                make.top.bottom.equalTo(self)
            }

            averageButton.snp.makeConstraints { make in
                make.left.equalTo(cheapButton.snp.right).inset(-18)
                make.right.equalTo(expensiveButton.snp.left).inset(-18)
                make.width.equalTo(cheapButton.snp.width)
                make.width.equalTo(expensiveButton.snp.width)
                make.top.bottom.equalTo(self)
            }

            expensiveButton.snp.makeConstraints { make in
                make.left.equalTo(averageButton.snp.right).inset(-18)
                make.right.equalTo(self)
                make.width.equalTo(cheapButton.snp.width)
                make.width.equalTo(averageButton.snp.width)
                make.top.bottom.equalTo(self)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            cheapButton.layer.cornerRadius = 2.0
            averageButton.layer.cornerRadius = 2.0
            expensiveButton.layer.cornerRadius = 2.0
            cheapButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.5)
            averageButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.5)
            expensiveButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.5)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Filter Tag Cells
fileprivate class SearchFilterTagCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 26, height: 26))

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
    private let titleLabel = UILabel()

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

// MARK: Filter More Controller
fileprivate class SearchFilterMoreController: UIViewController, UIGestureRecognizerDelegate {
    fileprivate let filterManager: SearchFilterManager
    private let onExtensionDismiss: ((SearchQuery?) -> Void)

    private let type: String
    private let tags: [String]

    private let headerView = SearchFilterMoreHeaderView()
    private let tableView = UITableView()
    private let applyView = SearchFilterMoreApplyView()

    init(searchQuery: SearchQuery, type: String, extensionDismiss: @escaping((SearchQuery?) -> Void)) {
        self.filterManager = SearchFilterManager(searchQuery: searchQuery)
        self.onExtensionDismiss = extensionDismiss

        self.type = type
        self.tags = filterManager.getMoreTypes(type: type)
        super.init(nibName: nil, bundle: nil)

        self.initViews()
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

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.resetButton.addTarget(self, action: #selector(actionReset(_:)), for: .touchUpInside)
        self.applyView.applyBtn.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        self.applyView.render(searchQuery: filterManager.searchQuery)
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
        let searchQuery = filterManager.reset(tags: self.tags)
        self.applyView.render(searchQuery: searchQuery)
        self.tableView.reloadData()
    }

    @objc func actionCancel(_ sender: Any) {
        self.onExtensionDismiss(nil)
        self.navigationController?.popViewController(animated: true)
    }

    @objc func actionApply(_ sender: Any) {
        self.onExtensionDismiss(filterManager.searchQuery)
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let tag = tags[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: SearchFilterTagCell.id) as! SearchFilterTagCell
        cell.render(title: tag, selected: filterManager.isSelected(tag: tag))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tag = tags[indexPath.row]

        if let cell = tableView.cellForRow(at: indexPath) as? SearchFilterTagCell {
            let searchQuery = self.filterManager.select(tag: tag, selected: cell.flip())
            self.applyView.render(searchQuery: searchQuery)
        }
    }
}