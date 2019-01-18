//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

fileprivate enum HomeTab {
    case Between
    case Search
    case Location

    var text: String {
        switch self {
        case .Between: return "EatBetween"
        case .Search: return "Search"
        case .Location: return "Neighbourhoods"
        }
    }

    var image: String {
        switch self {
        case .Between: return "Search-Card-Home-Tab-Between"
        case .Search: return "Search-Card-Home-Tab-Search"
        case .Location: return "Search-Card-Home-Tab-Location"
        }
    }

    var leftIcon: UIImage? {
        switch self {
        case .Between: return UIImage(named: "Search-Filter-Location-EatBetween")
        default: return UIImage(named: "Search-Header-Glass")
        }
    }

    var hint: String {
        switch self {
        case .Between: return "Enter Locations"
        case .Search: return "Search e.g. Italian in Orchard"
        case .Location: return "Search Location"
        }
    }

    var rightIcon: UIImage? {
        switch self {
        case .Search: return UIImage(named: "Search-Header-Filter")
        default: return nil
        }
    }

    var message: String {
        switch self {
        case .Between: return "Enter everyone’s location and we’ll find the most ideal spot for a meal together."
        case .Search: return "Search anything on Munch and we’ll give you the best recommendations."
        case .Location: return "Enter a location and we’ll tell you what’s delicious around."
        }
    }
}

class SearchHomeTabCard: SearchCardView {
    fileprivate let tabs: [HomeTab] = [.Between, .Search, .Location]
    fileprivate var currentTab: HomeTab = .Between {
        didSet {
            self.tabView.reloadData()
            self.messageLabel.text = currentTab.message

            self.backgroundImage.image = UIImage(named: currentTab.image)
            self.actionBar.leftIcon = currentTab.leftIcon
            self.actionBar.hint = currentTab.hint
            self.actionBar.rightIcon = currentTab.rightIcon
        }
    }

    let titleLabel = UILabel(style: .h2)
            .with(color: .white)
            .with(numberOfLines: 0)

    let createBtn: UIControl = {
        let label = UILabel(style: .h6)
                .with(color: .white)
                .with(text: "(Not Samantha? Create an account here.)")

        let button = UIControl()
        button.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.edges.equalTo(button)
        }
        return button
    }()

    let backgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: HomeTab.Between.image)
        return imageView
    }()

    let tabView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 32
        layout.minimumInteritemSpacing = 32

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SearchHomeTabCell.self, forCellWithReuseIdentifier: "SearchHomeTabCell")
        return collectionView
    }()

    private let messageLabel = UILabel(style: .h6)
            .with(color: .white)
            .with(numberOfLines: 0)

    private let actionBar = SearchHomeActionBar()

    var loggedInConstraints: Constraint!

    override func didLoad(card: SearchCard) {
        self.addSubview(backgroundImage)

        self.addSubview(titleLabel)
        self.addSubview(createBtn)
        self.addSubview(tabView)
        self.addSubview(messageLabel)
        self.addSubview(actionBar)

        let overlay = UIView()
        overlay.backgroundColor = .ba50
        backgroundImage.addSubview(overlay)

        overlay.snp.makeConstraints { maker in
            maker.edges.equalTo(backgroundImage)
        }

        backgroundImage.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self).inset(-topBottom - self.topSafeArea)
            maker.bottom.equalTo(self).inset(topBottom)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
        }

        createBtn.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
        }

        tabView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.height.equalTo(SearchHomeTabCell.height)

            loggedInConstraints = maker.top.equalTo(titleLabel.snp.bottom).inset(-8).priority(.high).constraint
            maker.top.equalTo(createBtn.snp.bottom).inset(-8).priority(.low)
        }

        messageLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(tabView.snp.bottom).inset(-16)
        }

        actionBar.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(messageLabel.snp.bottom).inset(-16)
        }

        self.tabView.dataSource = self
        self.tabView.delegate = self
        self.currentTab = .Between

        self.createBtn.addTarget(self, action: #selector(onCreateAccount), for: .touchUpInside)
        self.actionBar.addTarget(self, action: #selector(onBar), for: .touchUpInside)
        self.actionBar.rightControl.addTarget(self, action: #selector(onFilter), for: .touchUpInside)
    }

    override func willDisplay(card: SearchCard) {
        self.titleLabel.text = SearchHomeTabCard.title

        if Authentication.isAuthenticated() {
            createBtn.isHidden = true
            loggedInConstraints.activate()
        } else {
            createBtn.isHidden = false
            loggedInConstraints.deactivate()
        }
    }

    override class func height(card: SearchCard) -> CGFloat {
        let title = FontStyle.h2.height(text: SearchHomeTabCard.title, width: self.contentWidth)
        let tab = SearchHomeTabCell.height
        let message = FontStyle.h6.height(text: HomeTab.Between.message, width: self.contentWidth)
        let action: CGFloat = 40

        let min = topBottom + title + 8 + tab + 16 + message + 16 + action + 24 + topBottom
        if Authentication.isAuthenticated() {
            return min
        }

        let create = FontStyle.h6.height(text: "(Not Samantha? Create an account here.)", width: self.contentWidth)
        return min + 4 + create + 8
    }

    override class var cardId: String {
        return "HomeTab_2018-11-29"
    }
}

extension SearchHomeTabCard {
    @objc func onCreateAccount() {
        Authentication.requireAuthentication(controller: self.controller) { state in
            guard case .loggedIn = state else {
                return
            }

            self.controller.reset()
        }
    }

    @objc func onFilter() {
        self.controller.present(FilterRootController(searchQuery: self.controller.searchQuery) { query in
            if let query = query {
                self.controller.push(searchQuery: query)
            }
        }, animated: true)
    }

    @objc func onBar() {
        let searchQuery = self.controller.searchQuery

        switch self.currentTab {
        case .Search:
            self.controller.present(SuggestRootController(searchQuery: searchQuery) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }, animated: true)

        case .Between:
            let controller = FilterLocationBetweenController(searchQuery: searchQuery) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }
            self.controller.present(controller, animated: true)

        case .Location:
            let controller = FilterLocationSearchController(searchQuery: searchQuery) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }
            self.controller.present(controller, animated: true)
        }
    }
}

extension SearchHomeTabCard {
    class var title: String {
        return "\(salutation), \(name). Feeling hungry?"
    }

    class var salutation: String {
        let date = Date()
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)

        let total = (hour * 60) + minute
        if total >= 300 && total < 720 {
            return "Good Morning"
        } else if total >= 720 && total < 1020 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    class var name: String {
        return UserProfile.instance?.name ?? "Samantha"
    }
}

extension SearchHomeTabCard: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tab = tabs[indexPath.row]

        return collectionView.dequeue(type: SearchHomeTabCell.self, for: indexPath)
                .render(with: (text: tab.text, selected: tab == currentTab))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tab = tabs[indexPath.row]

        let width = UILabel.textWidth(font: SearchHomeTabCell.font, text: tab.text)
        return CGSize(width: width, height: SearchHomeTabCell.height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.currentTab = tabs[indexPath.row]
    }

    fileprivate class SearchHomeTabCell: UICollectionViewCell {
        static let height: CGFloat = 40
        static let font = UIFont.systemFont(ofSize: 19, weight: .semibold)

        private let nameLabel = UILabel(style: .h5)
                .with(font: font)
                .with(numberOfLines: 0)
                .with(color: .white)
                .with(alignment: .center)

        private let indicator: UIView = {
            let view = UIView()
            view.backgroundColor = .white
            return view
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(nameLabel)
            self.addSubview(indicator)

            nameLabel.snp.makeConstraints { maker in
                maker.edges.equalTo(self)
            }

            indicator.snp.makeConstraints { maker in
                maker.left.right.equalTo(self)
                maker.bottom.equalTo(self).inset(3)
                maker.height.equalTo(3)
            }
        }

        @discardableResult
        func render(with item: (text: String, selected: Bool)) -> SearchHomeTabCell {
            nameLabel.text = item.text
            indicator.isHidden = !item.selected
            return self
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class SearchHomeActionBar: UIControl {
    var leftIcon: UIImage? {
        didSet {
            self.leftImageView.image = leftIcon
        }
    }

    var hint: String? {
        didSet {
            self.hintLabel.text = hint
        }
    }

    var rightIcon: UIImage? {
        didSet {
            self.rightControl.isHidden = rightIcon == nil
        }
    }

    private let leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .ba85
        return imageView
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .ba75
        label.text = "Search"
        return label
    }()


    fileprivate let rightControl: UIControl = {
        let control = UIControl()

        let imageView = UIImageView()
        imageView.tintColor = .ba85
        imageView.image = UIImage(named: "Search-Header-Filter")
        control.addSubview(imageView)

        let hairline = UIView()
        hairline.backgroundColor = .ba20
        control.addSubview(hairline)

        imageView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(control).inset(8)
            maker.right.equalTo(control).inset(10)
            maker.width.equalTo(imageView.snp.height)
        }

        hairline.snp.makeConstraints { maker in
            maker.width.equalTo(1)
            maker.left.equalTo(imageView).inset(-10)
            maker.top.bottom.equalTo(imageView)
        }
        return control
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(leftImageView)
        self.addSubview(hintLabel)
        self.addSubview(rightControl)

        self.layer.cornerRadius = 3
        self.backgroundColor = .white

        self.snp.makeConstraints { maker in
            maker.height.equalTo(40)
        }

        self.leftImageView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(10)
            maker.left.equalTo(self).inset(12)
            maker.width.equalTo(leftImageView.snp.height)
        }

        self.hintLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(leftImageView.snp.right).inset(-10)
            maker.right.equalTo(rightControl.snp.left).inset(-10)
        }

        self.rightControl.snp.makeConstraints { maker in
            maker.right.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

