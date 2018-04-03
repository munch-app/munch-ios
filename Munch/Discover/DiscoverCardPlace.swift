//
// Created by Fuxing Loh on 5/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftyJSON

class SearchNewPlaceCard: UITableViewCell, SearchCardView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Newly Opened"
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        label.textColor = UIColor.black.withAlphaComponent(0.72)
        label.backgroundColor = .white
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 110, height: 120)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchPlaceCardPlaceCell.self, forCellWithReuseIdentifier: "SearchPlaceCardPlaceCell")
        return collectionView
    }()

    private var controller: DiscoverController!
    private var places = [Place]()
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
            make.height.equalTo(120)
        }
    }

    func render(card: SearchCard, controller: DiscoverController) {
        if self.card?.instanceId == card.instanceId {
            return
        }

        self.controller = controller
        self.card = card

        let places = card["places"].compactMap({ Place(json: $0.1) })
        if self.places != places {
            self.places = places
            self.collectionView.setContentOffset(.zero, animated: false)
            self.collectionView.reloadData()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var cardId: String {
        return "injected_NewPlace_20180209"
    }
}

extension SearchNewPlaceCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let place = places[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchPlaceCardPlaceCell", for: indexPath) as! SearchPlaceCardPlaceCell
        cell.render(place: place)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        controller.select(placeId: place.id)
    }
}

class SearchRecentPlaceCard: UITableViewCell, SearchCardView {
    private let titleLabel: SearchHeaderCardLabel = {
        let label = SearchHeaderCardLabel()
        label.text = "Recently Viewed"
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 110, height: 120)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.register(SearchPlaceCardPlaceCell.self, forCellWithReuseIdentifier: "SearchPlaceCardPlaceCell")
        return collectionView
    }()

    private var controller: DiscoverController!
    private var places = [Place]()
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
            make.height.equalTo(120)
        }
    }

    func render(card: SearchCard, controller: DiscoverController) {
        if self.card?.instanceId == card.instanceId {
            return
        }

        self.controller = controller
        self.card = card

        let places = card["places"].compactMap({ Place(json: $0.1) })
        if self.places != places {
            self.places = places
            self.collectionView.setContentOffset(.zero, animated: false)
            self.collectionView.reloadData()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var cardId: String {
        return "injected_RecentPlace_20180209"
    }
}

extension SearchRecentPlaceCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let place = places[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchPlaceCardPlaceCell", for: indexPath) as! SearchPlaceCardPlaceCell
        cell.render(place: place)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        controller.select(placeId: place.id)
    }
}

fileprivate class SearchPlaceCardPlaceCell: UICollectionViewCell {
    let imageView: MunchImageView = {
        let imageView = MunchImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(hex: "dedede")
        return imageView
    }()
    let typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.85)
        label.isUserInteractionEnabled = false
        label.backgroundColor = .white
        return label
    }()
    let nameLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        nameLabel.backgroundColor = .white

        nameLabel.textContainer.maximumNumberOfLines = 2
        nameLabel.textContainer.lineBreakMode = .byTruncatingTail
        nameLabel.textContainer.lineFragmentPadding = 2
        nameLabel.textContainerInset = UIEdgeInsets(topBottom: 0, leftRight: -2)
        nameLabel.isUserInteractionEnabled = false
        return nameLabel
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(typeLabel)
        self.addSubview(nameLabel)

        imageView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self)
        }

        typeLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(imageView.snp.bottom).inset(-1)
            make.height.equalTo(14)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(typeLabel.snp.bottom).inset(-2)
            make.bottom.equalTo(self)

            make.height.equalTo(30)
        }

        self.layoutIfNeeded()
    }

    func render(place: Place) {
        imageView.render(sourcedImage: place.images?.get(0))
        nameLabel.text = place.name
        let neighbourhood = place.location.neighbourhood ?? ""
        let tag = place.tag.explicits.get(0) ?? ""
        typeLabel.text = neighbourhood + " ⋅ " + tag.capitalized
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.roundCorners(.allCorners, radius: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}