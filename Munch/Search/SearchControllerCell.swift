//
// Created by Fuxing Loh on 17/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

enum SearchResultType {
    case empty
    case loading
    case headerRestaurant
    case place(Place)
    case assumption(AssumptionQueryResult)
    case recentlyViewed
}

class SearchCellHeaderRestaurant: UITableViewCell {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Restaurant")
        imageView.tintColor = UIColor.primary300
        return imageView
    }()
    private let labelView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        label.textColor = UIColor(hex: "555555")
        label.text = "RESTAURANTS"
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(iconView)
        self.addSubview(labelView)

        iconView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.width.height.equalTo(20)
        }

        labelView.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.left.equalTo(iconView.snp.right).inset(-6)
            make.top.equalTo(self).inset(12)

            make.top.bottom.equalTo(iconView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchCellHeaderRestaurant"
    }
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
    private let tagTokenConfig = TagTokenConfig()
    private let textTokenConfig = TextTokenConfig()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Assumption-Tag")
        imageView.tintColor = UIColor.primary300
        return imageView
    }()
    private let tagView: MunchTagView = {
        let tagView = MunchTagView(extends: true)
        return tagView
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 150, height: 160)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.register(SearchCellAssumptionPlace.self, forCellWithReuseIdentifier: "SearchCellAssumptionPlace")
        return collectionView
    }()
    private let applyButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white

        button.setTitle("SHOW ALL", for: .normal)
        button.setTitleColor(UIColor(hex: "383838"), for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 13, weight: .medium)

        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(hex: "808080").cgColor
        return button
    }()

    private var controller: SearchController!
    private var searchQuery: SearchQuery!
    private var places = [Place]()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(iconView)
        self.addSubview(tagView)
        self.addSubview(collectionView)
        self.addSubview(applyButton)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        applyButton.addTarget(self, action: #selector(actionApply(_:)), for: .touchUpInside)

        iconView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)

            make.top.bottom.equalTo(tagView)
        }

        tagView.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.left.equalTo(iconView.snp.right).inset(-8)
            make.top.equalTo(self).inset(12)
            make.height.equalTo(30)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(tagView.snp.bottom).inset(-15)
            make.height.equalTo(160)
        }

        applyButton.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(36)

            make.top.equalTo(collectionView.snp.bottom).inset(-12)
            make.bottom.equalTo(self).inset(12)
        }
    }

    func render(queryResult: AssumptionQueryResult, controller: SearchController) {
        self.controller = controller
        self.searchQuery = queryResult.searchQuery
        self.places = queryResult.places

        self.tagView.removeAll()
        for token in queryResult.tokens {
            if let token = token as? AssumptionQueryResult.TagToken {
                self.tagView.add(text: token.text, config: tagTokenConfig)
            } else if let token = token as? AssumptionQueryResult.TextToken {
                self.tagView.add(text: token.text, config: textTokenConfig)
            }
        }

        self.collectionView.reloadData()

        let title = DiscoverFilterBottomView.countTitle(count: queryResult.count, prefix: "Show all")
        applyButton.setTitle(title, for: .normal)
    }

    @objc func actionApply(_ sender: Any) {
        self.controller.select(searchQuery: searchQuery)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchCellAssumptionQueryResult"
    }

    struct TagTokenConfig: MunchTagViewConfig {
        let font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        let textColor = UIColor(hex: "222222")
        let backgroundColor = UIColor.bgTag
        let extra = CGSize(width: 20, height: 13)
    }

    struct TextTokenConfig: MunchTagViewConfig {
        let font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        let textColor = UIColor(hex: "222222")
        let backgroundColor = UIColor.white
        let extra = CGSize(width: 2, height: 13)
    }
}

extension SearchCellAssumptionQueryResult: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let place = places[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCellAssumptionPlace", for: indexPath) as! SearchCellAssumptionPlace
        cell.render(place: place)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        controller.select(placeId: place.id)
    }
}

fileprivate class SearchCellAssumptionPlace: UICollectionViewCell {
    let imageView: MunchImageView = {
        let imageView = MunchImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(hex: "DEDEDE")
        return imageView
    }()
    let typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = UIColor.black.withAlphaComponent(0.85)
        label.isUserInteractionEnabled = false
        label.backgroundColor = .white
        return label
    }()
    let nameLabel: UITextView = {
        let nameLabel = UITextView()
        nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
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
            make.top.equalTo(imageView.snp.bottom).inset(-3)
            make.height.equalTo(14)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(typeLabel.snp.bottom).inset(-3)
            make.bottom.equalTo(self)

            make.height.equalTo(32)
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

class SearchCellPlace: UITableViewCell {
    private let tagTokenConfig = TagTokenConfig()

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

    private let tagView = MunchTagView(count: 4)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)
        containerView.addSubview(placeImageView)

        containerView.addSubview(nameLabel)
        containerView.addSubview(locationLabel)
        containerView.addSubview(tagView)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(5)
        }

        placeImageView.snp.makeConstraints { make in
            make.left.top.bottom.equalTo(containerView).inset(8)
            make.width.equalTo(80)
            make.height.equalTo(64)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(placeImageView.snp.right).inset(-10)
            make.right.equalTo(containerView).inset(8)

            make.top.equalTo(containerView).inset(11)
        }

        tagView.snp.makeConstraints { (make) in
            make.left.equalTo(placeImageView.snp.right).inset(-10)
            make.right.equalTo(containerView).inset(8)

            make.height.equalTo(19)
            make.top.equalTo(nameLabel.snp.bottom).inset(-3)
        }

        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(placeImageView.snp.right).inset(-10)
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

        self.tagView.removeAll()
        for tag in place.tag.explicits.prefix(3) {
            self.tagView.add(text: tag.capitalized, config: tagTokenConfig)
        }
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

    struct TagTokenConfig: MunchTagViewConfig {
        let font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        let textColor = UIColor(hex: "222222")
        let backgroundColor = UIColor.white
        let extra = CGSize(width: 10, height: 5)
    }
}

class SearchCellRecentlyViewed: UITableViewCell {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Recently-Viewed")
        imageView.tintColor = UIColor.primary300
        return imageView
    }()
    private let labelView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        label.textColor = UIColor(hex: "555555")
        label.text = "RECENTLY VIEWED"
        return label
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 130, height: 140)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.register(SearchCellAssumptionPlace.self, forCellWithReuseIdentifier: "SearchCellAssumptionPlace")
        return collectionView
    }()

    private var controller: SearchController!
    private var places = [Place]()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(iconView)
        self.addSubview(labelView)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        iconView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.width.height.equalTo(20)
        }

        labelView.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.left.equalTo(iconView.snp.right).inset(-6)
            make.top.equalTo(self).inset(12)

            make.top.bottom.equalTo(iconView)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(labelView.snp.bottom).inset(-15)
            make.height.equalTo(140)
            make.bottom.equalTo(self).inset(12)
        }
    }

    func render(controller: SearchController) {
        self.controller = controller
        let recentDatabase = RecentDatabase(name: "RecentlyViewedPlace", maxItems: 20)
        self.places = recentDatabase.get()
                .compactMap({ $1 })
                .compactMap({ SearchClient.parseResult(result: $0) })
                .compactMap({ $0 as? Place })
        self.collectionView.reloadData()

        if places.isEmpty {
            labelView.isHidden = true
            iconView.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchCellRecentlyViewed"
    }
}

extension SearchCellRecentlyViewed: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let place = places[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCellAssumptionPlace", for: indexPath) as! SearchCellAssumptionPlace
        cell.render(place: place)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        controller.select(placeId: place.id)
    }
}