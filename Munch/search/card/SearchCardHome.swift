//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchHomeTabCard: UITableViewCell, SearchCardView {
    let tabs = ["Location", "Inspiration", "Occasion"]

    let titleLabel = UILabel()
            .with(style: .h2)
            .with(numberOfLines: 0)

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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(titleLabel)
        self.addSubview(collectionView)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
        }

        collectionView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(titleLabel.snp.bottom).inset(-topBottom)
            maker.bottom.equalTo(self).inset(topBottom)
            maker.height.equalTo(SearchHomeTabCell.size.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
        titleLabel.text = "Hi Steve, how would you like to discover delicious by?"
    }

    static var cardId: String {
        return "HomeTab_2018-11-29"
    }
}

extension SearchHomeTabCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchHomeTabCell", for: indexPath) as! SearchHomeTabCell
        cell.nameLabel.text = tabs[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO
    }
}

fileprivate class SearchHomeTabCell: UICollectionViewCell {
    static let size = CGSize(width: 128, height: 80)
    let imageView: SizeImageView = {
        let imageView = SizeImageView(points: size)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.whisper100
        return imageView
    }()

    let nameLabel = UILabel()
            .with(size: 17, weight: 600, color: .ba75)
            .with(alignment: .center)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(nameLabel)

        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
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