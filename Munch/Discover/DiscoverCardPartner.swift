//
// Created by Fuxing Loh on 5/5/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

import SnapKit
import SwiftyJSON

class SearchInstagramPartnerCard: UITableViewCell, SearchCardView, SFSafariViewControllerDelegate {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        label.textColor = .white
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.text = " "
        return label
    }()
    private let infoButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.setImage(UIImage(named: "Search-Partner-Info"), for: .normal)
        return button
    }()
    private let actionButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 4
        button.backgroundColor = .white
        button.setTitle("More from ...", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets.init(topBottom: 12, leftRight: 18)
        button.setTitleColor(.primary500, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return button
    }()
    static let collectionWidth = UIScreen.main.bounds.width / 2
    static let collectionHeight = collectionWidth + 40
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: collectionWidth, height: collectionHeight)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(SearchInstagramPartnerContentCell.self, forCellWithReuseIdentifier: "SearchInstagramPartnerContentCell")
        return collectionView
    }()

    private var controller: DiscoverController!
    private var contents = [InstagramPartnerCardContent]()
    private var card: SearchCard?
    private var username: String?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .primary300
        self.addSubview(titleLabel)
        self.addSubview(infoButton)
        self.addSubview(actionButton)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).inset(leftRight)
            make.right.equalTo(infoButton.snp.left).inset(-12)
            make.top.equalTo(self).inset(topBottom)
            make.height.equalTo(32)
        }

        infoButton.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.right.equalTo(self).inset(leftRight)
            make.width.height.equalTo(20)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).inset(-topBottom)
            make.height.equalTo(SearchInstagramPartnerCard.collectionHeight)
        }

        actionButton.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.right.lessThanOrEqualTo(self).inset(24)
            make.top.equalTo(collectionView.snp.bottom).inset(-24)
            make.bottom.equalTo(self).inset(topBottom)
        }

        infoButton.addTarget(self, action: #selector(onInfoClick), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(onActionClick), for: .touchUpInside)
    }

    func render(card: SearchCard, controller: DiscoverController) {
        if self.card?.instanceId == card.instanceId {
            return
        }
        self.controller = controller
        self.card = card

        self.titleLabel.text = card.dict(name: "title") as? String
        if let username = card.dict(name: "username") as? String {
            self.username = username
            self.actionButton.setTitle("More from @\(username)", for: .normal)
        }

        self.contents = card.decode(name: "contents", [InstagramPartnerCardContent].self) ?? []
        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.reloadData()
    }

    @objc func onInfoClick() {
        let alert = UIAlertController(title: "Munch Content Partner", message: "Open partner.munch.app?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { action in
            let safari = SFSafariViewController(url: URL(string: "https://partner.munch.app")!)
            safari.delegate = self
            self.controller.present(safari, animated: true, completion: nil)
        }))
        controller.present(alert, animated: true, completion: nil)
    }

    @objc func onActionClick() {
        if let username = self.username, let url = URL(string: "https://instagram.com/" + username) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            controller.present(safari, animated: true, completion: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var cardId: String {
        return "injected_PartnerInstagram_20180505"
    }
}

struct InstagramPartnerCardContent: Codable {
    var place: Place?
    var images: [String: String]?

    struct Place: Codable {
        var id: String?
        var name: String?

        // This is same as PlaceClient.Place but because place client is not codable
    }
}

extension SearchInstagramPartnerCard: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contents.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchInstagramPartnerContentCell", for: indexPath) as! SearchInstagramPartnerContentCell
        cell.render(content: contents[indexPath.row], username: username ?? "")
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let placeId = contents[indexPath.row].place?.id {
            controller.select(placeId: placeId)
        }
    }
}

fileprivate class SearchInstagramPartnerContentCell: UICollectionViewCell {
    let imageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        imageView.backgroundColor = UIColor(hex: "dedede")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    let titleLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        nameLabel.textColor = .white
        nameLabel.backgroundColor = .clear

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
        self.addSubview(titleLabel)

        imageView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(imageView.snp.bottom).inset(-5)
            make.bottom.equalTo(self)

            make.height.equalTo(35)
        }
    }

    func render(content: InstagramPartnerCardContent, username: String) {
        imageView.render(images: content.images)

        if let name = content.place?.name {
            titleLabel.text = name + " by @\(username)"
        }
    }

    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.layer.cornerRadius = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}