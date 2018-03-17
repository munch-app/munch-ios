//
// Created by Fuxing Loh on 17/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

enum SearchResultType {
    case empty
    case loading
    case place(Place)
    case assumption(AssumptionQueryResult)
}

class SearchCellLoading: UITableViewCell {
    private let containerView: ShimmerView = {
        let view = ShimmerView(color: UIColor(hex: "F3F3F3"))
        return view
    }()

    private let tagView: ShimmerView = {
        let view = ShimmerView(color: UIColor(hex: "E6E6E6"))
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)
        self.addSubview(tagView)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(14)
        }

        tagView.snp.makeConstraints { make in
            make.left.equalTo(containerView).inset(16)
            make.top.bottom.equalTo(containerView).inset(16)
            make.width.equalTo(150)
            make.height.equalTo(24)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.contentView.layer.cornerRadius = 3
        containerView.contentView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)

        tagView.contentView.layer.cornerRadius = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "DiscoverFilterCellLoading"
    }
}

class SearchCellNoResult: UITableViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.text = "No Results"
        label.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        label.textColor = UIColor(hex: "333333")
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(20)
            make.bottom.equalTo(self).inset(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchCellNoResult"
    }
}

class SearchCellAssumptionQueryResult: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()
    private let tagCollection: MunchTagCollectionView = {
        let tagCollection = MunchTagCollectionView(horizontalSpacing: 6, backgroundColor: UIColor(hex: "F0F0F0"), showFullyVisibleOnly: false)
        tagCollection.isUserInteractionEnabled = false
        return tagCollection
    }()
    private let applyButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.tintColor = UIColor(hex: "202020")
        button.setImage(UIImage(named: "Search-Right-Arrow-Small"), for: .normal)

        button.setTitleColor(UIColor(hex: "202020"), for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        button.contentEdgeInsets.right = 0
        button.titleEdgeInsets.bottom = 2
        button.titleEdgeInsets.right = -1

        button.contentHorizontalAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        button.isUserInteractionEnabled = false
        return button
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)
        containerView.addSubview(tagCollection)
        containerView.addSubview(applyButton)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(10)
            make.bottom.equalTo(self).inset(4)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.equalTo(containerView).inset(10)
            make.right.equalTo(containerView)
            make.top.equalTo(containerView).inset(8)
            make.height.equalTo(32)
        }

        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(tagCollection.snp.bottom).inset(-8)
            make.bottom.equalTo(containerView).inset(8)
            make.right.equalTo(containerView).inset(8)
        }
    }

//    func render(query: AssumedSearchQuery) {
//        var types = [MunchTagCollectionType]()
//
//        for token in query.tokens {
//            if let token = token as? AssumedSearchQuery.TagToken {
//                types.append(.assumptionTag(token.text))
//            } else if let token = token as? AssumedSearchQuery.TextToken {
//                types.append(.assumptionText(token.text))
//            }
//        }
//
//        tagCollection.replaceAll(types: types)
//        let title = DiscoverFilterBottomView.countTitle(count: query.resultCount)
//
//        if title.lowercased() == "no results" {
//            applyButton.setTitleColor(UIColor.primary600, for: .normal)
//            applyButton.tintColor = UIColor.primary600
//            applyButton.setTitle("No Results", for: .normal)
//        } else {
//            applyButton.setTitleColor(UIColor(hex: "202020"), for: .normal)
//            applyButton.tintColor = UIColor(hex: "202020")
//            applyButton.setTitle(title, for: .normal)
//        }
//    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 3
        containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchCellAssumptionQueryResult"
    }
}

class SearchCellPlace: UITableViewCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(hex: "404040")
        return label
    }()
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(hex: "535353")
        return label
    }()
    private let placeImageView: ShimmerImageView = {
        let imageView = ShimmerImageView()
        return imageView
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)
        containerView.addSubview(placeImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(locationLabel)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(2)
        }

        placeImageView.snp.makeConstraints { make in
            make.left.top.bottom.equalTo(containerView).inset(8)
            make.height.equalTo(40)
            make.width.equalTo(50)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(placeImageView.snp.right).inset(-12)
            make.right.equalTo(containerView).inset(8)
            make.top.equalTo(containerView).inset(11)
        }

        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(placeImageView.snp.right).inset(-12)
            make.right.equalTo(containerView).inset(8)
            make.bottom.equalTo(containerView).inset(11)
        }
    }

    func render(place: Place) {
        placeImageView.render(sourcedImage: place.images?.get(0))
        nameLabel.text = place.name

        let string = NSMutableAttributedString()

        if let latLng = place.location.latLng, let distance = MunchLocation.distance(asMetric: latLng) {
            string.append(distance.set(style: .default { make in
                make.color = UIColor(hex: "606060")
            }))
            string.append(NSAttributedString(string: ", "))
        }

        let locationName = place.location.neighbourhood ?? ""
        string.append(locationName.set(style: .default { make in
            make.color = UIColor(hex: "505050")
        }))

        if !(place.open ?? true) {
            string.append(NSAttributedString(string: ", "))
            string.append("Perm Closed".set(style: .default { make in
                make.color = UIColor.primary500
            }))
        }

        locationLabel.attributedText = string
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 3
        containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchCellPlace"
    }
}
