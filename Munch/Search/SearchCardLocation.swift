//
// Created by Fuxing Loh on 5/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON

class SearchContainersCard: UITableViewCell, SearchCardView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Locations"
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
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
    private var card: SearchCard?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
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
        if self.card?.instanceId == card.instanceId {
            return
        }

        self.controller = controller
        self.card = card

        self.containers = card["containers"].map({ Container(json: $0.1) })
        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
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
        imageView.contentMode = .scaleAspectFill
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

    func render(container: Container) {
        nameLabel.text = container.name
        imageView.render(sourcedImage: container.images?.get(0))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.roundCorners([.topLeft, .topRight], radius: 3)
    }
}