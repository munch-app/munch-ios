//
// Created by Fuxing Loh on 27/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import BEMCheckBox

class SearchSuggestCellAssumption: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(2)
            // TODO
        }
    }

    func render(query: AssumedSearchQuery) {
        // TODO
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
        return "SearchSuggestCellAssumption"
    }
}

class SearchSuggestCellHeader: UITableViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        label.textColor = UIColor(hex: "555555")
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(14)
            make.bottom.equalTo(self).inset(14)
        }
    }

    func render(title: String) {
        label.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchSuggestCellHeader"
    }
}

class SearchSuggestCellNoResult: UITableViewCell {
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
        return "SearchSuggestCellNoResult"
    }
}

class SearchSuggestCellLocation: UITableViewCell {
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: 95, height: 90)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchSuggestCellLocationGridCell.self, forCellWithReuseIdentifier: "SearchSuggestCellLocationGridCell")
        return collectionView
    }()

    var controller: SearchSuggestController!
    var locations: [SearchLocationType]!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).inset(1)
            make.bottom.equalTo(self).inset(1)
            make.height.equalTo(94)
        }
    }

    func render(locations: [SearchLocationType], controller: SearchSuggestController) {
        self.controller = controller
        self.locations = locations
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchSuggestCellLocation"
    }
}

extension SearchSuggestCellLocation: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchSuggestCellLocationGridCell", for: indexPath) as! SearchSuggestCellLocationGridCell

        switch locations[indexPath.row] {
        case .nearby:
            let selected = controller.manager.isSelected(location: nil)
            cell.render(text: "Nearby", image: UIImage(named: "Search-Location-Nearby"), selected: selected)
        case let .anywhere(location):
            let selected = controller.manager.isSelected(location: location)
            cell.render(text: "Anywhere", image: UIImage(named: "Search-Location-Anywhere"), selected: selected)
        case let .location(location):
            let selected = controller.manager.isSelected(location: location)
            cell.render(text: location.name, image: UIImage(named: "Search-Location-Pin"), selected: selected)
        case let .container(container):
            let selected = controller.manager.isSelected(container: container)
            cell.render(text: container.name, image: UIImage(named: "Search-Location-Pin"), selected: selected)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch locations[indexPath.row] {
        case .nearby:
            controller.manager.select(location: nil, save: false)
        case .anywhere:
            controller.manager.select(location: SearchFilterManager.anywhere, save: false)
        case let .location(location):
            controller.manager.select(location: location)
        case let .container(container):
            controller.manager.select(container: container)
        }
        collectionView.reloadData()
    }

    fileprivate class SearchSuggestCellLocationGridCell: UICollectionViewCell {
        let containerView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(hex: "F0F0F0")
            return view
        }()
        let imageView: MunchImageView = {
            let imageView = MunchImageView()
            imageView.tintColor = UIColor(hex: "333333")
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return imageView
        }()
        let nameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
            label.textColor = UIColor(hex: "444444")
            label.textAlignment = .center
            label.numberOfLines = 2
            return label
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(containerView)
            containerView.addSubview(imageView)
            containerView.addSubview(nameLabel)

            imageView.snp.makeConstraints { make in
                make.top.equalTo(containerView).inset(12)
                make.bottom.equalTo(nameLabel.snp.top)
                make.centerX.equalTo(containerView)
                make.height.equalTo(imageView.snp.width)
            }

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(containerView).inset(4)
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
            containerView.layer.cornerRadius = 3.0
            containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
        }

        func render(text: String?, image: UIImage?, selected: Bool) {
            nameLabel.text = text
            imageView.image = image

            containerView.backgroundColor = selected ? .primary400 : UIColor(hex: "F0F0F0")
            imageView.tintColor = selected ? .white : UIColor(hex: "444444")
            nameLabel.textColor = selected ? .white : UIColor(hex: "444444")
        }

        func render(text: String?, sourcedImage: SourcedImage?, selected: Bool) {
            nameLabel.text = text
            imageView.render(sourcedImage: sourcedImage)

            containerView.backgroundColor = selected ? .primary400 : UIColor(hex: "F0F0F0")
            imageView.tintColor = selected ? .white : UIColor(hex: "444444")
            nameLabel.textColor = selected ? .white : UIColor(hex: "444444")
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class SearchSuggestCellTag: UITableViewCell {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "444444")
        return titleLabel
    }()
    private let checkButton: BEMCheckBox = {
        let checkButton = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        checkButton.boxType = .circle
        checkButton.lineWidth = 1.5
        checkButton.tintColor = UIColor(hex: "444444")
        checkButton.animationDuration = 0.25
        checkButton.isEnabled = false

        checkButton.onCheckColor = .white
        checkButton.onTintColor = .primary
        checkButton.onFillColor = .primary
        return checkButton
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
        containerView.addSubview(titleLabel)
        containerView.addSubview(checkButton)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(2)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(containerView).inset(12)
            make.left.equalTo(containerView).inset(18)
            make.right.equalTo(checkButton.snp.left).inset(-12)
        }

        checkButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(containerView).inset(10)
            make.right.equalTo(containerView).inset(18)
        }
    }

    func render(title: String, selected: Bool) {
        titleLabel.text = title
        checkButton.setOn(selected, animated: false)
    }

    /**
     Flip the switch on check button
     */
    func flip() -> Bool {
        let flip = !checkButton.on
        checkButton.setOn(flip, animated: true)
        return flip
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
        return "SearchSuggestCellTag"
    }
}

class SearchSuggestCellTiming: UITableViewCell {
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16 // LeftRight

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SearchSuggestCellTimingGridCell.self, forCellWithReuseIdentifier: "SearchSuggestCellTimingGridCell")
        return collectionView
    }()

    var controller: SearchSuggestController!
    var timings: [SearchTimingType]!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.height.equalTo(40).priority(999)
            make.top.bottom.equalTo(self)
        }
    }

    func render(timings: [SearchTimingType], controller: SearchSuggestController) {
        self.controller = controller
        self.timings = timings
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchSuggestCellTiming"
    }
}

extension SearchSuggestCellTiming: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchSuggestCellTimingGridCell", for: indexPath) as! SearchSuggestCellTimingGridCell

        switch timings[indexPath.row] {
        case .now:
            let selected = controller.manager.isSelected(hour: "Open Now")
            cell.render(text: "Open Now", image: UIImage(named: "Search-Timing-Present"), selected: selected)
        case .breakfast:
            let selected = controller.manager.isSelected(hour: "Breakfast")
            cell.render(text: "Breakfast", image: nil, selected: selected)
        case .lunch:
            let selected = controller.manager.isSelected(hour: "Lunch")
            cell.render(text: "Lunch", image: nil, selected: selected)
        case .dinner:
            let selected = controller.manager.isSelected(hour: "Dinner")
            cell.render(text: "Dinner", image: nil, selected: selected)
        case .supper:
            let selected = controller.manager.isSelected(hour: "Supper")
            cell.render(text: "Supper", image: nil, selected: selected)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch timings[indexPath.row] {
        case .now:
            return CGSize(width: SearchSuggestCellTimingGridCell.textWidth(text: "Open Now") + 36 + 20, height: 36)
        case .breakfast:
            return CGSize(width: SearchSuggestCellTimingGridCell.textWidth(text: "Breakfast") + 36, height: 36)
        case .lunch:
            return CGSize(width: SearchSuggestCellTimingGridCell.textWidth(text: "Lunch") + 36, height: 36)
        case .dinner:
            return CGSize(width: SearchSuggestCellTimingGridCell.textWidth(text: "Dinner") + 36, height: 36)
        case .supper:
            return CGSize(width: SearchSuggestCellTimingGridCell.textWidth(text: "Supper") + 36, height: 36)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch timings[indexPath.row] {
        case .now:
            controller.manager.select(hour: "Open Now")
        case .breakfast:
            controller.manager.select(hour: "Breakfast")
        case .lunch:
            controller.manager.select(hour: "Lunch")
        case .dinner:
            controller.manager.select(hour: "Dinner")
        case .supper:
            controller.manager.select(hour: "Supper")
        }
        // Note: It only Reload Current Item
        collectionView.reloadItems(at: [indexPath])
    }

    fileprivate class SearchSuggestCellTimingGridCell: UICollectionViewCell {
        static let labelFont = UIFont.systemFont(ofSize: 14.0, weight: .semibold)

        class func textWidth(text: String) -> CGFloat {
            return UILabel.textWidth(font: labelFont, text: text)
        }

        let containerView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(hex: "F0F0F0")
            return view
        }()
        let imageView: MunchImageView = {
            let imageView = MunchImageView()
            imageView.tintColor = UIColor(hex: "444444")
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        let nameLabel: UILabel = {
            let nameLabel = UILabel()
            nameLabel.backgroundColor = .clear
            nameLabel.font = labelFont
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)

            nameLabel.numberOfLines = 1
            nameLabel.isUserInteractionEnabled = false

            nameLabel.textAlignment = .right
            return nameLabel
        }()

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(containerView)
            containerView.addSubview(nameLabel)
            containerView.addSubview(imageView)

            nameLabel.snp.makeConstraints { make in
                make.right.equalTo(containerView).inset(18)
                make.top.bottom.equalTo(containerView)
                make.left.equalTo(containerView)

                make.height.equalTo(36)
            }

            imageView.snp.makeConstraints { make in
                make.top.bottom.equalTo(containerView).inset(8)
                make.left.equalTo(containerView).inset(11)
                make.width.height.equalTo(20)
            }

            containerView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            containerView.layer.cornerRadius = 3.0
            containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
        }

        func render(text: String?, image: UIImage?, selected: Bool) {
            nameLabel.text = text
            DispatchQueue.main.async {
                self.imageView.image = image
            }

            if selected {
                containerView.backgroundColor = .primary400
                nameLabel.textColor = .white
                imageView.tintColor = .white
            } else {
                containerView.backgroundColor = UIColor(hex: "F0F0F0")
                nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)
                imageView.tintColor = UIColor(hex: "444444")
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class SearchSuggestCellPlace: UITableViewCell {
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


        let locationName = place.location.neighbourhood ?? ""
        if let latLng = place.location.latLng, let distance = MunchLocation.distance(asMetric: latLng) {
            let string = NSMutableAttributedString()
            string.append(distance.set(style: .default { make in
                make.color = UIColor(hex: "606060")
            }))
            string.append(NSAttributedString(string: ", "))
            string.append(locationName.set(style: .default { make in
                make.color = UIColor(hex: "505050")
            }))
            locationLabel.attributedText = string
        } else {
            locationLabel.text = locationName
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
        return "SearchSuggestCellPlace"
    }
}