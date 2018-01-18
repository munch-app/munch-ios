//
//  SearchCardInjected.swift
//  Munch
//
//  Created by Fuxing Loh on 20/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON

class SearchNoLocationCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.text = "No Location"
        titleLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(26)
        }

        descriptionLabel.text = "You have turned off your location service. Turn it on for better suggestion?"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
        }

        actionButton.layer.cornerRadius = 3
        actionButton.backgroundColor = .primary
        actionButton.setTitle("Enable Location", for: .normal)
        actionButton.contentEdgeInsets.left = 32
        actionButton.contentEdgeInsets.right = 32
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
        actionButton.addTarget(self, action: #selector(enableLocation(button:)), for: .touchUpInside)
    }

    @objc func enableLocation(button: UIButton) {
        if MunchLocation.isEnabled {
            controller.render(searchQuery: controller.searchQuery)
        } else {
            MunchLocation.requestLocation()
            actionButton.setTitle("Refresh Search", for: .normal)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
    }

    static var cardId: String {
        return "injected_NoLocation_20171020"
    }
}

class SearchNoResultCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)

        titleLabel.text = "No Results"
        titleLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(26)
        }

        descriptionLabel.text = "We couldn't find anything. Try broadening your search?"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
            make.bottom.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
    }

    static var cardId: String {
        return "injected_NoResult_20171208"
    }
}

class SearchNoResultLocationCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var searchQuery: SearchQuery!
    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.text = "No Results"
        titleLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(26)
        }

        descriptionLabel.text = "We couldn't find anything in that location. Try searching anywhere instead?"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-20)
        }

        actionButton.layer.cornerRadius = 3
        actionButton.backgroundColor = .primary
        actionButton.setTitle("Search Anywhere", for: .normal)
        actionButton.contentEdgeInsets.left = 32
        actionButton.contentEdgeInsets.right = 32
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
        actionButton.addTarget(self, action: #selector(onAction(button:)), for: .touchUpInside)
    }

    @objc func onAction(button: UIButton) {
        controller.render(searchQuery: self.searchQuery)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
        self.searchQuery = SearchQuery(json: card["searchQuery"])
        self.controller = controller

        let locationName = card["locationName"].string ?? "Location"
        if (locationName == "Nearby") {
            titleLabel.text = "No Results found Nearby"
            descriptionLabel.text = "We couldn't find anything near you. Try searching anywhere instead?"
        } else {
            titleLabel.text = "No Results in \(locationName)"
            descriptionLabel.text = "We couldn't find anything in \(locationName). Try searching anywhere instead?"
        }
    }

    static var cardId: String {
        return "injected_NoResultLocation_20171208"
    }
}

class SearchContainersCard: UITableViewCell, SearchCardView {
    private static let preferredOrder = [
        ("Shopping Mall", "Malls"),
        ("Hawker Centre", "Hawkers"),
        ("Coffeeshop", "Coffeeshops")
    ]
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "Search-Container-Big")
        imageView.tintColor = UIColor.black.withAlphaComponent(0.72)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 21.0, weight: .semibold)
        label.textColor = UIColor.black.withAlphaComponent(0.72)
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 120, height: 110)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchContainersCardContainerCell.self, forCellWithReuseIdentifier: "SearchContainersCardContainerCell")
        return collectionView
    }()

    private var controller: SearchController!
    private var containers = [Container]()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(collectionView)
        self.addSubview(iconView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        iconView.snp.makeConstraints { make in
            make.top.bottom.equalTo(titleLabel)
            make.left.equalTo(self).inset(leftRight)
        }

        titleLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(leftRight)
            make.left.equalTo(iconView.snp.right).inset(-5)
            make.top.equalTo(self).inset(topBottom)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).inset(-topBottom)
            make.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(110)
        }
    }

    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
        self.titleLabel.text = getTitle(card: card)

        let containers = card["containers"].map({ Container(json: $0.1) })
        if self.containers != containers {
            self.containers = containers
            self.collectionView.setContentOffset(.zero, animated: false)
            self.collectionView.reloadData()
        }
    }

    private func getTitle(card: SearchCard) -> String? {
        let types = Set(card["types"].map({ $0.1.stringValue }))
        var typeNames = [String]()

        for preferred in SearchContainersCard.preferredOrder {
            if (types.contains(preferred.0)) {
                typeNames.append(preferred.1)
            }
        }

        if (typeNames.count < 3) {
            return typeNames.joined(separator: " and ")
        }

        var nameBuilder = ""

        for (index, name) in typeNames.enumerated() {
            if (index == typeNames.count - 1) {
                // Last
                nameBuilder = nameBuilder + " and " + name
            } else if (index == 0) {
                // First
                nameBuilder = name
            } else {
                nameBuilder = nameBuilder + ", " + name
            }
        }
        return nameBuilder
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var cardId: String {
        return "injected_Containers_20171211"
    }
}

extension SearchContainersCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return containers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let container = containers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchContainersCardContainerCell", for: indexPath) as! SearchContainersCardContainerCell
        cell.render(container: container)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let container = containers[indexPath.row]
        var searchQuery = controller.searchQuery
        searchQuery.filter.containers = [container]
        controller.render(searchQuery: searchQuery)
    }
}

fileprivate class SearchContainersCardContainerCell: UICollectionViewCell {
    let imageView: MunchImageView = {
        let imageView = MunchImageView()
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        return imageView
    }()

    let nameLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)

        nameLabel.textContainer.maximumNumberOfLines = 2
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainer.lineFragmentPadding = 2
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 4, leftRight: 4)
        nameLabel.isUserInteractionEnabled = false
        return nameLabel
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let containerView = UIView()
        containerView.layer.cornerRadius = 3
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "DDDDDD").cgColor
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        self.addSubview(containerView)

        imageView.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.top.equalTo(containerView)
            make.bottom.equalTo(nameLabel.snp.top)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.bottom.equalTo(containerView)
            make.height.equalTo(40)
        }

        containerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        self.layoutIfNeeded()
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.roundCorners([.topLeft, .topRight], radius: 3)
    }

    func render(container: Container) {
        nameLabel.text = container.name
        imageView.render(sourcedImage: container.images?.get(0))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}