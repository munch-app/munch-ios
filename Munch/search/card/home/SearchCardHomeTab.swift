//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

fileprivate enum HomeTab {
    case Between
    case Feed
    case Location

    var text: String {
        switch self {
        case .Between: return "EatBetween"
        case .Feed: return "Inspiration"
        case .Location: return "Neighbourhoods"
        }
    }

    var image: String {
        switch self {
        case .Between: return "Search-Card-Home-Tab-Between"
        case .Feed: return "Search-Card-Home-Tab-Feed"
        case .Location: return "Search-Card-Home-Tab-Location"
        }
    }
}

class SearchHomeTabCard: SearchCardView {
    fileprivate let tabs: [HomeTab] = [.Between, .Feed, .Location]

    let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)
    let createBtn: UIButton = {
        let label = UILabel(style: .h6)
                .with(text: "(Not Samantha? Create an account here.)")

        let button = UIButton()
        button.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.edges.equalTo(button)
        }
        return button
    }()

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = SearchHomeTabCell.size
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 24

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SearchHomeTabCell.self, forCellWithReuseIdentifier: "SearchHomeTabCell")
        return collectionView
    }()

    var loggedInConstraints: Constraint!

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(createBtn)
        self.addSubview(collectionView)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
        }

        collectionView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.bottom.equalTo(self).inset(topBottom)
            maker.height.equalTo(SearchHomeTabCell.size.height)

            loggedInConstraints = maker.top.equalTo(titleLabel.snp.bottom).inset(-topBottom).priority(.high).constraint
            maker.top.equalTo(createBtn.snp.bottom).inset(-topBottom).priority(.low)
        }

        createBtn.addTarget(self, action: #selector(onCreateAccount), for: .touchUpInside)
        createBtn.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
        }
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
        let min = self.topBottom +
                FontStyle.h2.height(text: SearchHomeTabCard.title, width: self.contentWidth) +
                self.topBottom +
                SearchHomeTabCell.size.height +
                self.topBottom

        if Authentication.isAuthenticated() {
            return min
        }

        return min + 4 + FontStyle.h6.height(text: "(Not Samantha? Create an account here.)", width: self.contentWidth)
    }

    @objc func onCreateAccount() {
        Authentication.requireAuthentication(controller: self.controller) { state in
            guard case .loggedIn = state else {
                return
            }

            self.controller.reset()
        }
    }

    override class var cardId: String {
        return "HomeTab_2018-11-29"
    }

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

extension SearchHomeTabCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tab = tabs[indexPath.row]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchHomeTabCell", for: indexPath) as! SearchHomeTabCell
        cell.nameLabel.text = tab.text
        cell.imageView.image = UIImage(named: tab.image)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch tabs[indexPath.row] {
        case .Between:
            let controller = FilterLocationBetweenController(searchQuery: SearchQuery()) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }
            self.controller.present(controller, animated: true)

        case .Feed:
            self.controller.tabBarController?.selectedIndex = MunchTabBarItem.Feed.index

        case .Location:
            self.controller.push(searchQuery: SearchQuery(feature: .Location))
        }
    }
}

fileprivate class SearchHomeTabCell: UICollectionViewCell {
    static let size = CGSize(width: 168, height: 88)
    let imageView: SizeImageView = {
        let imageView = SizeImageView(points: size)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.whisper100
        return imageView
    }()

    let nameLabel = UILabel(style: .h4)
            .with(numberOfLines: 0)
            .with(color: .white)
            .with(alignment: .center)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(nameLabel)

        let overlay = UIView()
        overlay.backgroundColor = .ba50
        imageView.addSubview(overlay)

        overlay.snp.makeConstraints { maker in
            maker.edges.equalTo(imageView)
        }

        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(8)
            maker.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.roundCorners(.allCorners, radius: 3)
    }
}