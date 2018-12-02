//
// Created by Fuxing Loh on 2018-12-02.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class FilterItemCellTiming: UITableViewCell {
    private let label = UILabel(style: .h1).with(text: "Timing")

    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = .zero

        collectionView.register(FilterItemCellTimingNow.self, forCellWithReuseIdentifier: String(describing: FilterItemCellTimingNow.self))
        collectionView.register(FilterItemCellTimingTag.self, forCellWithReuseIdentifier: String(describing: FilterItemCellTimingTag.self))
        return collectionView
    }()

    let manager: FilterManager

    var timings: [FilterItem.Timing] = [
        .now,
        .tag(Tag(tagId: "f749ab1a-358c-4ba2-adb8-04a3accf46cb", name: "Breakfast", type: .Timing)),
        .tag(Tag(tagId: "1be094a8-b9f5-43ca-9af7-f0ae2d87afb2", name: "Lunch", type: .Timing)),
        .tag(Tag(tagId: "32d11ac3-afb2-4e1e-a798-97771958294c", name: "Dinner", type: .Timing)),
        .tag(Tag(tagId: "97c3121f-7947-4950-8a63-027ef1d6337a", name: "Supper", type: .Amenities)),
    ]

    init(manager: FilterManager) {
        self.manager = manager
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none

        self.addSubview(label)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(16)
        }

        collectionView.snp.makeConstraints { maker in
            maker.top.equalTo(label.snp_bottom).inset(-16)
            maker.left.right.equalTo(self)
            maker.height.equalTo(40).priority(999)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    func reloadData() {
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterItemCellTiming: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timings.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch timings[indexPath.row] {
        case .now:
            return CGSize(width: 106 + 20, height: 36)
        default:
            return CGSize(width: 100, height: 36)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch timings[indexPath.row] {
        case .now:
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterItemCellTimingNow.self), for: indexPath)
        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterItemCellTimingTag.self), for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch timings[indexPath.row] {
        case let .now:
            let cell = cell as! FilterItemCellTimingNow
            cell.render(text: "Open Now", selected: true)

        case let .tag(tag):
            let cell = cell as! FilterItemCellTimingTag
            cell.render(text: tag.name, selected: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let timing = timings[indexPath.row]
//        manager.select(timing: timing)

//        switch timing {
//
    }

//
//            searchQuery.filter.hour.name = name
//
//            let date = Date()
//            searchQuery.filter.hour.day = Hour.Day.today.rawValue.lowercased()
//            searchQuery.filter.hour.open = Hour.machineFormatter.string(from: date)
//            // If time now is 23:00 onwards, OpenNow close time will be set to 23:59
//            if (23 == Calendar.current.component(.hour, from: date)) {
//                searchQuery.filter.hour.close = "23:59"
//            } else {
//                searchQuery.filter.hour.close = Hour.machineFormatter.string(from: date.addingTimeInterval(30 * 60))
//            }

}

fileprivate class FilterItemCellTimingNow: UICollectionViewCell {
    static let labelFont = UIFont.systemFont(ofSize: 14.0, weight: .semibold)

    class func textWidth(text: String) -> CGFloat {
        return UILabel.textWidth(font: labelFont, text: text)
    }

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor(hex: "444444")
        imageView.image = UIImage(named: "Search-Timing-Present")
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
        nameLabel.text = "Open Now".localized()
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

    func render(text: String?, selected: Bool) {
        nameLabel.text = text

        if selected {
            containerView.backgroundColor = .primary500
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

fileprivate class FilterItemCellTimingTag: UICollectionViewCell {
    static let labelFont = UIFont.systemFont(ofSize: 14.0, weight: .semibold)

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()
    let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.backgroundColor = .clear
        nameLabel.font = labelFont
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)

        nameLabel.numberOfLines = 1
        nameLabel.isUserInteractionEnabled = false

        nameLabel.textAlignment = .center
        return nameLabel
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(containerView)
        containerView.addSubview(nameLabel)

        nameLabel.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
            make.height.equalTo(36)
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

    func render(text: String?, selected: Bool) {
        nameLabel.text = text

        if selected {
            containerView.backgroundColor = .primary500
            nameLabel.textColor = .white
        } else {
            containerView.backgroundColor = UIColor(hex: "F0F0F0")
            nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}