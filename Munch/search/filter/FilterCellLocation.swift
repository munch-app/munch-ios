//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString
import Localize_Swift

class FilterItemCellLocation: UITableViewCell {
    private let label = UILabel(style: .h2).with(text: "Location")
    private let manager: FilterManager

    init(manager: FilterManager) {
        self.manager = manager
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none

        self.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(16)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    func reloadData() {
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//class SearchFilterCellLocation: UITableViewCell {
//    private let titleLabel: SearchFilterHeader = {
//        let header = SearchFilterHeader()
//        header.text = "Location".localized()
//        return header
//    }()
//    private let moreButton: UIButton = {
//        let button = UIButton()
//        button.setTitle("See All".localized(), for: .normal)
//        button.setTitleColor(UIColor.primary500, for: .normal)
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
//
//        button.contentHorizontalAlignment = .right
//        button.semanticContentAttribute = .forceRightToLeft
//        return button
//    }()
//
//    fileprivate let collectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
//        layout.itemSize = CGSize(width: 95, height: 90)
//        layout.scrollDirection = .horizontal
//        layout.minimumLineSpacing = 16
//
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.showsVerticalScrollIndicator = false
//        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.backgroundColor = UIColor.white
//        collectionView.register(SearchFilterCellLocationGridCell.self, forCellWithReuseIdentifier: "SearchFilterCellLocationGridCell")
//        return collectionView
//    }()
//
//    let manager: SearchFilterManager
//    let controller: SearchFilterController
//
//    var locations = [SearchFilterType.Location]()
//
//    init(manager: SearchFilterManager, controller: SearchFilterController) {
//        self.manager = manager
//        self.controller = controller
//        super.init(style: .default, reuseIdentifier: nil)
//        self.selectionStyle = .none
//        self.addSubview(titleLabel)
//        self.addSubview(moreButton)
//        self.addSubview(collectionView)
//
//        self.collectionView.dataSource = self
//        self.collectionView.delegate = self
//        self.moreButton.addTarget(self, action: #selector(action(more:)), for: .touchUpInside)
//
//        titleLabel.snp.makeConstraints { make in
//            make.left.equalTo(self)
//            make.top.equalTo(self).inset(20)
//        }
//
//        moreButton.snp.makeConstraints { make in
//            make.right.equalTo(self).inset(24)
//            make.top.bottom.equalTo(titleLabel)
//        }
//
//        collectionView.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).inset(1)
//            make.left.right.equalTo(self)
//            make.height.equalTo(94)
//            make.bottom.equalTo(self).inset(20)
//        }
//    }
//
//    func render(locations: [SearchFilterType.Location]) {
//        self.locations = locations
//        self.collectionView.reloadData()
//    }
//
//    @objc func action(more: Any) {
//        self.controller.goTo(.location)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//extension SearchFilterCellLocation: UICollectionViewDataSource, UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return locations.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchFilterCellLocationGridCell", for: indexPath) as! SearchFilterCellLocationGridCell
//
//        switch locations[indexPath.row] {
//        case .nearby(let selected):
//            cell.render(text: "Nearby".localized(), image: UIImage(named: "Search-Location-Nearby"), selected: selected)
//
//        case .anywhere(_, let selected):
//            cell.render(text: "Anywhere".localized(), image: UIImage(named: "Search-Location-Anywhere"), selected: selected)
//
//        case .area(let area, let selected):
//            cell.render(text: area.name, image: UIImage(named: "Search-Location-Pin"), selected: selected)
//        }
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        switch locations[indexPath.row] {
//        case .nearby:
//            manager.select(area: nil, persist: false)
//            Analytics.logEvent("search_filter_action", parameters: [
//                AnalyticsParameterItemCategory: "apply_location_nearby" as NSObject
//            ])
//
//        case .anywhere(let area, _):
//            manager.select(area: area, persist: false)
//            Analytics.logEvent("search_filter_action", parameters: [
//                AnalyticsParameterItemCategory: "apply_location_anywhere" as NSObject
//            ])
//
//        case .area(let area, _):
//            manager.select(area: area, persist: true)
//            Analytics.logEvent("search_filter_action", parameters: [
//                AnalyticsParameterItemID: "location-\(area.areaId ?? "")" as NSObject,
//                AnalyticsParameterItemCategory: "apply_location" as NSObject
//            ])
//
//        }
//    }
//
//    fileprivate class SearchFilterCellLocationGridCell: UICollectionViewCell {
//        let containerView: UIView = {
//            let view = UIView()
//            view.backgroundColor = UIColor(hex: "F0F0F0")
//            return view
//        }()
//        let imageView: MunchImageView = {
//            let imageView = MunchImageView()
//            imageView.tintColor = UIColor(hex: "333333")
//            imageView.contentMode = .scaleAspectFill
//            imageView.clipsToBounds = true
//            return imageView
//        }()
//        let nameLabel: UILabel = {
//            let label = UILabel()
//            label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
//            label.textColor = UIColor(hex: "444444")
//            label.textAlignment = .center
//            label.numberOfLines = 2
//            return label
//        }()
//
//        override init(frame: CGRect = .zero) {
//            super.init(frame: frame)
//            self.addSubview(containerView)
//            containerView.addSubview(imageView)
//            containerView.addSubview(nameLabel)
//
//            imageView.snp.makeConstraints { make in
//                make.top.equalTo(containerView).inset(12)
//                make.bottom.equalTo(nameLabel.snp.top)
//                make.centerX.equalTo(containerView)
//                make.height.equalTo(imageView.snp.width)
//            }
//
//            nameLabel.snp.makeConstraints { make in
//                make.left.right.equalTo(containerView).inset(4)
//                make.bottom.equalTo(containerView)
//                make.height.equalTo(40)
//            }
//
//            containerView.snp.makeConstraints { make in
//                make.edges.equalTo(self)
//            }
//            self.layoutIfNeeded()
//        }
//
//        fileprivate override func layoutSubviews() {
//            super.layoutSubviews()
//            containerView.layer.cornerRadius = 3.0
//            containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
//        }
//
//        func render(text: String?, image: UIImage?, selected: Bool) {
//            nameLabel.text = text
//            imageView.image = image
//
//            containerView.backgroundColor = selected ? .primary400 : UIColor(hex: "F0F0F0")
//            imageView.tintColor = selected ? .white : UIColor(hex: "444444")
//            nameLabel.textColor = selected ? .white : UIColor(hex: "444444")
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//    }
//}