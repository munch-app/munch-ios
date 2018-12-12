//
// Created by Fuxing Loh on 2018-12-12.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardHomeAwardCollection: SearchCardView {

    private let titleLabel = UILabel(style: .h2)
            .with(text: "Award Winning Places")
            .with(numberOfLines: 0)
    private let subLabel = UILabel(style: .h6)
            .with(text: "If trophies were edible, you'd have em' at theses joints.")
            .with(numberOfLines: 0)

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = SearchCardHomeAwardCollectionCell.size
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 24

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear

        collectionView.register(type: SearchCardHomeAwardCollectionCell.self)
        return collectionView
    }()

    var collections = [UserPlaceCollection]()

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(subLabel)
        self.addSubview(collectionView)

        collectionView.delegate = self
        collectionView.dataSource = self

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(self).inset(self.topBottom)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(self.leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
        }

        collectionView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.height.equalTo(SearchCardHomeAwardCollectionCell.size.height)
            maker.top.equalTo(subLabel.snp.bottom).inset(-24)
            maker.bottom.equalTo(self).inset(self.topBottom * 2)
        }
    }

    override func willDisplay(card: SearchCard) {
        guard let collections = card.decode(name: "collections", [UserPlaceCollection].self) else {
            return
        }

        self.collections = collections
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
    }

    override class var cardId: String {
        return "HomeAwardCollection_2018-12-10"
    }
}

extension SearchCardHomeAwardCollection: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return SearchCardHomeAwardCollectionCell.size
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: SearchCardHomeAwardCollectionCell.self, for: indexPath)
        cell.collection = collections[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collectionId = collections[indexPath.row].collectionId else {
            return
        }
        let name = collections[indexPath.row].name
        let collection = SearchQuery.Collection(name: name, collectionId: collectionId)
        self.controller.push(searchQuery: SearchQuery(collection: collection))
    }
}


fileprivate class SearchCardHomeAwardCollectionCell: UICollectionViewCell {
    public static let width = (UIScreen.main.bounds.width - 48) * 0.6
    public static let size = CGSize(width: width, height: width)

    let imageView: SizeImageView = {
        let imageView = SizeImageView(points: size)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.whisper200
        return imageView
    }()

    let nameLabel = UILabel(style: .h3)
            .with(numberOfLines: 0)
            .with(color: .white)
            .with(alignment: .center)

    var collection: UserPlaceCollection! {
        didSet {
            self.nameLabel.text = collection.name
            self.imageView.render(image: collection.image)
        }
    }

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