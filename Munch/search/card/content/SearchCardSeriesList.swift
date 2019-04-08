//
// Created by Fuxing Loh on 2019-03-07.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SearchCardSeriesList: SearchCardView {
    var contents: [CreatorContent] = []
    var options: [String: Any] = ["expand": "width"]

    let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 1)

    let subtitleLabel = UILabel(style: .h6)
            .with(numberOfLines: 2)

    let collectionView: UICollectionView = {
        let layout = MunchHorizontalSnap()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = .white
        return collectionView
    }()

    override func didLoad(card: SearchCard) {
        if let options = card["options"] as? [String: Any] {
            self.options = options
        }
        let series: CreatorSeries? = card.decode(name: "series", CreatorSeries.self)

        titleLabel.text = series?.title
        self.addSubview(titleLabel) { (maker: ConstraintMaker) -> Void in
            maker.top.equalTo(self).inset(topBottom)
            maker.left.right.equalTo(self).inset(24)
        }

        subtitleLabel.text = series?.subtitle
        self.addSubview(subtitleLabel) { (maker: ConstraintMaker) -> Void in
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
            maker.left.right.equalTo(self).inset(24)
        }

        self.registerCells(collectionView: self.collectionView)
        self.addSubview(collectionView) { (maker: ConstraintMaker) -> Void in
            maker.top.equalTo(subtitleLabel.snp.bottom).inset(-24)
            maker.left.right.equalTo(self)
            maker.bottom.equalTo(self).inset(topBottom).priority(.high)

            maker.height.equalTo(SearchSeriesContentCard.size(options: options).height)
        }

        let horizontalSnap = collectionView.collectionViewLayout as? MunchHorizontalSnap
        horizontalSnap?.itemSize = SearchSeriesContentCard.size(options: options)
        self.layoutIfNeeded()
    }

    override func willDisplay(card: SearchCard) {
        let series: CreatorSeries? = card.decode(name: "series", CreatorSeries.self)
        self.contents = card.decode(name: "contents", [CreatorContent].self) ?? []
        self.collectionView.reloadData()

        titleLabel.text = series?.title
        subtitleLabel.text = series?.subtitle
    }

    override class var cardId: String {
        return "SeriesList_2019-02-25"
    }
}

extension SearchCardSeriesList: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func registerCells(collectionView: UICollectionView) {
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(type: SearchSeriesContentCard.self)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contents.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let content = contents[indexPath.row]
        return collectionView.dequeue(type: SearchSeriesContentCard.self, for: indexPath)
                .render(with: content)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return SearchSeriesContentCard.size(options: options)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = contents[indexPath.row]
        let controller = ContentPageController(contentId: content.contentId, content: content)
        self.controller.navigationController?.pushViewController(controller, animated: true)
    }
}

class SearchSeriesContentCard: UICollectionViewCell {
    private static let width = UIScreen.main.bounds.size.width
    private static let subtitleHeight = FontStyle.h5.height(text: " ", width: .greatestFiniteMagnitude)
    private static let bodyHeight = UILabel.textHeight(withWidth: .greatestFiniteMagnitude, font: .systemFont(ofSize: 15), text: " \n \n ")

    private let image = SizeShimmerImageView(points: width, height: width)
    private let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 3)
            .with(color: .white)
            .with(alignment: .center)
    private let subtitleLabel = UILabel(style: .h5)
            .with(numberOfLines: 1)
            .with(color: .secondary700)
    private let bodyLabel = UILabel(style: .regular)
            .with(numberOfLines: 3)
            .with(font: .systemFont(ofSize: 15))

    override init(frame: CGRect) {
        super.init(frame: frame)
        image.layer.cornerRadius = 3
        self.addSubview(image) { (maker: ConstraintMaker) -> Void in
            maker.left.right.top.equalTo(self)
        }

        let container = UIView()
        container.backgroundColor = .ba45
        self.image.addSubview(container) { maker in
            maker.edges.equalTo(image)
        }

        container.addSubview(titleLabel) { (maker: ConstraintMaker) -> Void in
            maker.edges.equalTo(image).inset(24)
        }

        self.addSubview(subtitleLabel) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self)
            maker.top.equalTo(image.snp.bottom).inset(-12)
        }

        let body = UIView()
        self.addSubview(body) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self)
            maker.height.equalTo(SearchSeriesContentCard.bodyHeight)
            maker.top.equalTo(subtitleLabel.snp.bottom).inset(-4)
            maker.bottom.equalTo(self)
        }

        body.addSubview(bodyLabel) { (maker: ConstraintMaker) -> Void in
            maker.left.top.right.equalTo(body)
        }
    }

    func render(with content: CreatorContent) -> SearchSeriesContentCard {
        image.render(image: content.image)
        titleLabel.text = content.title
        subtitleLabel.text = content.subtitle
        bodyLabel.text = content.body
        return self
    }

    static func size(options: [String: Any]) -> CGSize {
        let width = getWidth(options: options)
        let bottomHeight = 12 + 4 + bodyHeight + subtitleHeight
        if let expand = options["expand"] as? String, expand == "height" {
            return CGSize(width: width, height: bottomHeight + width * 1.2)
        } else {
            return CGSize(width: width, height: bottomHeight + width * 0.6)
        }

    }

    static func getWidth(options: [String: Any]) -> CGFloat {
        if let expand = options["expand"] as? String, expand == "height" {
            return UIScreen.main.bounds.size.width * 0.5
        }
        return UIScreen.main.bounds.size.width - 48
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}