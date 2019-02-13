//
// Created by Fuxing Loh on 2018-12-13.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

struct SearchBetweenAnchor: Codable {
    var title: String
    var uniqueId: String?
}

class SearchCardBetweenHeader: SearchCardView {
    private let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)
    private let shareBtn = MunchButton(style: .secondaryOutline)
            .with(text: "SHARE")

    private let editControl = UIControl()
    private let editLabel = UILabel(style: .regular)
    private let editIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "RIP-Card-Edit")
        imageView.tintColor = .ba75
        return imageView
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(type: AnchorCell.self)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private var anchors = [SearchBetweenAnchor]()

    override func didLoad(card: SearchCard) {
        self.addSubview(shareBtn)
        self.addSubview(titleLabel)
        self.addSubview(collectionView)
        self.addSubview(editControl)

        editControl.addSubview(editLabel)
        editControl.addSubview(editIcon)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.shareBtn.addTarget(self, action: #selector(onShare), for: .touchUpInside)
        self.editControl.addTarget(self, action: #selector(onEdit), for: .touchUpInside)

        shareBtn.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.left.equalTo(self).inset(leftRight)
            maker.right.equalTo(shareBtn.snp.left).inset(-16)
            maker.top.equalTo(self).inset(topBottom)
        }

        editControl.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-8)

            editIcon.snp.makeConstraints { maker in
                maker.width.height.equalTo(16)
                maker.left.equalTo(editControl)
                maker.centerY.equalTo(editControl)
            }

            editLabel.snp.makeConstraints { maker in
                maker.left.equalTo(editIcon.snp.right).inset(-8)
                maker.right.equalTo(self).inset(leftRight)
                maker.bottom.top.equalTo(editControl)
            }
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(editControl.snp.bottom).inset(-16)
            make.bottom.equalTo(self).inset(topBottom)
            make.height.equalTo(48)
        }
    }

    override func willDisplay(card: SearchCard) {
        self.titleLabel.text = "Ideal Locations"
        self.anchors = card.decode(name: "anchors", [SearchBetweenAnchor].self) ?? []

        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()

        let count = self.controller.searchQuery.filter.location.points.count
        editLabel.text = "Between \(count) Locations"
    }

    @objc func onEdit() {
        let controller = FilterLocationBetweenController(searchQuery: self.controller.searchQuery) { query in
            if let query = query {
                self.controller.push(searchQuery: query)
            }
        }
        self.controller.present(controller, animated: true)
    }

    @objc func onShare() {
        guard let qid = self.controller.qid else {
            return
        }

        if let url = URL(string: "https://www.munch.app/search?qid=\(qid)&g=GB10") {
            let controller = UIActivityViewController(activityItems: ["EatBetween", url], applicationActivities: nil)
            controller.excludedActivityTypes = [.airDrop, .addToReadingList, UIActivity.ActivityType.openInIBooks]

            MunchAnalytic.logSearchQueryShare(searchQuery: self.controller.searchQuery, trigger: "search_card_between_header")
            self.controller.present(controller, animated: true)
        }
    }

    override class func height(card: SearchCard) -> CGFloat {
        let min = topBottom + topBottom + 16 + 48 + 8 + 16
        let text = "Ideal Locations"
        let width = contentWidth - 16 - 72 // Button and it's left margin
        return min + UILabel.textHeight(withWidth: width, font: FontStyle.h2.font, text: text)
    }

    override class var cardId: String {
        return "BetweenHeader_2018-12-13"
    }
}

extension SearchCardBetweenHeader: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return anchors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: AnchorCell.self, for: indexPath)
        cell.label.text = anchors[indexPath.row].title
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = FontStyle.h5.width(text: anchors[indexPath.row].title)
        return CGSize(width: width + 32, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let uniqueId = anchors[indexPath.row].uniqueId else {
            return
        }

        self.controller.searchTableView.scrollTo(uniqueId: uniqueId)
    }

    fileprivate class AnchorCell: UICollectionViewCell {
        let label = UILabel(style: .h5).with(alignment: .center)

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(label)
            self.backgroundColor = .whisper100

            label.snp.makeConstraints { maker in
                maker.edges.equalTo(self)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        fileprivate override func layoutSubviews() {
            super.layoutSubviews()
            self.layer.cornerRadius = 3
        }
    }
}