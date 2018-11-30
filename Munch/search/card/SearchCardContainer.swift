////
//// Created by Fuxing Loh on 12/5/18.
//// Copyright (c) 2018 Munch Technologies. All rights reserved.
////
//
//import Foundation
//import UIKit
//import MapKit
//import Localize_Swift
//
//import FirebaseAnalytics
//import SnapKit
//import SwiftRichString
//
//import SwiftyJSON
//
//class SearchAreaClusterListCard: UITableViewCell, SearchCardView {
//    private let titleLabel: SearchHeaderCardLabel = {
//        let label = SearchHeaderCardLabel()
//        label.text = "Discover Locations".localized()
//        return label
//    }()
//    private let collectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
//        layout.itemSize = SearchAreaClusterListCardCell.size
//        layout.scrollDirection = .horizontal
//        layout.minimumLineSpacing = 18
//
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.showsVerticalScrollIndicator = false
//        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.backgroundColor = UIColor.clear
//        collectionView.register(SearchAreaClusterListCardCell.self, forCellWithReuseIdentifier: "SearchAreaClusterListCardCell")
//        return collectionView
//    }()
//
//    private var controller: SearchController!
//    private var areas = [Area]()
//
//    private var instanceId: String?
//
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        self.selectionStyle = .none
//        self.addSubview(titleLabel)
//        self.addSubview(collectionView)
//
//        self.collectionView.dataSource = self
//        self.collectionView.delegate = self
//
//        titleLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(self).inset(leftRight)
//            make.top.equalTo(self).inset(topBottom)
//        }
//
//        collectionView.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.top.equalTo(titleLabel.snp.bottom).inset(-topBottom)
//            make.bottom.equalTo(self).inset(topBottom)
//            make.height.equalTo(110)
//        }
//    }
//
//    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
//        if self.instanceId == card.instanceId {
//            return
//        }
//
//        self.controller = controller
//        self.instanceId = card.instanceId
//
//        if let areas = card.decode(name: "areas", [Area].self) {
//            self.areas = areas
//        } else {
//            self.areas = []
//        }
//        self.collectionView.setContentOffset(.zero, animated: false)
//        self.collectionView.reloadData()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private(set) static var cardId: String = "injected_AreaClusterList_20180621"
//}
//
//extension SearchAreaClusterListCard: UICollectionViewDataSource, UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return areas.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let area = areas[indexPath.row]
//
//        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
//            AnalyticsParameterItemID: "area-\(area.areaId)" as NSObject,
//            AnalyticsParameterItemCategory: "search_areas" as NSObject
//        ])
//
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchAreaClusterListCardCell", for: indexPath) as! SearchAreaClusterListCardCell
//        cell.render(area: area)
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let area = areas[indexPath.row]
//
//        self.controller.search { query in
//            query.filter.area = area
//        }
//
//        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
//            AnalyticsParameterItemID: "area-\(area.areaId)" as NSObject,
//            AnalyticsParameterContentType: "search_areas" as NSObject
//        ])
//    }
//
//    fileprivate class SearchAreaClusterListCardCell: UICollectionViewCell {
//        static let size = CGSize(width: 120, height: 110)
//        let imageView: SizeImageView = {
//            let imageView = SizeImageView(points: size)
//            imageView.contentMode = .scaleAspectFill
//            imageView.backgroundColor = UIColor(hex: "dedede")
//            return imageView
//        }()
//
//        let nameLabel: UITextView = {
//            let nameLabel = UITextView()
//            nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
//            nameLabel.textColor = UIColor.black.withAlphaComponent(0.72)
//            nameLabel.backgroundColor = .white
//
//            nameLabel.textContainer.maximumNumberOfLines = 2
//            nameLabel.textContainer.lineBreakMode = .byTruncatingTail
//            nameLabel.textContainer.lineFragmentPadding = 2
//            nameLabel.textContainerInset = UIEdgeInsets(topBottom: 4, leftRight: 4)
//            nameLabel.isUserInteractionEnabled = false
//            return nameLabel
//        }()
//
//        override init(frame: CGRect = .zero) {
//            super.init(frame: frame)
//
//            let containerView = UIView()
//            containerView.backgroundColor = .clear
//            containerView.layer.cornerRadius = 3
//            containerView.layer.borderWidth = 1
//            containerView.layer.borderColor = UIColor(hex: "DDDDDD").cgColor
//            containerView.addSubview(imageView)
//            containerView.addSubview(nameLabel)
//            self.addSubview(containerView)
//
//            imageView.snp.makeConstraints { make in
//                make.left.right.equalTo(containerView)
//                make.top.equalTo(containerView)
//                make.bottom.equalTo(nameLabel.snp.top)
//            }
//
//            nameLabel.snp.makeConstraints { make in
//                make.left.right.equalTo(containerView)
//                make.bottom.equalTo(containerView)
//                make.height.equalTo(40)
//            }
//
//            containerView.snp.makeConstraints { make in
//                make.edges.equalTo(self)
//            }
//
//            self.layoutIfNeeded()
//        }
//
//        func render(area: Area) {
//            nameLabel.text = area.name
//            imageView.render(image: area.images?.get(0))
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//
//        fileprivate override func layoutSubviews() {
//            super.layoutSubviews()
//            self.imageView.roundCorners([.topLeft, .topRight], radius: 3)
//        }
//    }
//
//}
//
//class SearchAreaClusterHeaderCard: UITableViewCell, SearchCardView {
//    static let contentWidth = width - (leftRight + leftRight)
//    static let nameFont = UIFont.systemFont(ofSize: 21.0, weight: .medium)
//    static let descriptionFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
//    static let imageSize: CGSize = {
//        let imageWidth = width - leftRight - leftRight
//        return CGSize(width: imageWidth, height: imageWidth / 3.3)
//    }()
//
//    private let topImageView: SizeImageView = {
//        let imageView = SizeImageView.init(points: imageSize.width, height: imageSize.height)
//        imageView.tintColor = .white
//
//        let overlay = UIView()
//        imageView.addSubview(overlay)
//        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.33)
//        overlay.snp.makeConstraints { make in
//            make.edges.equalTo(imageView)
//        }
//        return imageView
//    }()
//    private let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = nameFont
//        label.textColor = UIColor.white
//        label.numberOfLines = 0
//        return label
//    }()
//    private let descriptionLabel: UILabel = {
//        let label = UILabel()
//        label.font = descriptionFont
//        label.textColor = UIColor(hex: "434343")
//        label.numberOfLines = 0
//        return label
//    }()
//    private let addressLineView = AddressLineView()
//    private let hourLineView = HourLineView()
//    private let grid = UIView()
//
//    private var descriptionAddressConstraint: Constraint!
//    private var imageAddressConstraint: Constraint!
//
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        self.selectionStyle = .none
//
//        grid.addSubview(topImageView)
//        grid.addSubview(nameLabel)
//        grid.addSubview(descriptionLabel)
//        grid.addSubview(addressLineView)
//        grid.addSubview(hourLineView)
//        self.addSubview(grid)
//
//        grid.snp.makeConstraints { make in
//            make.left.right.equalTo(self).inset(leftRight)
//            make.top.bottom.equalTo(self).inset(topBottom)
//        }
//
//        topImageView.snp.makeConstraints { make in
//            make.top.left.right.equalTo(grid)
//            make.height.equalTo(SearchAreaClusterHeaderCard.imageSize.height)
//        }
//
//        nameLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(topImageView).inset(8)
//            make.bottom.equalTo(topImageView).inset(8)
//        }
//
//        descriptionLabel.snp.makeConstraints { make in
//            make.left.right.equalTo(grid)
//            make.top.equalTo(topImageView.snp.bottom).inset(-8)
//        }
//
//        addressLineView.snp.makeConstraints { make in
//            make.left.right.equalTo(grid)
//            make.height.equalTo(AddressLineView.height).priority(999)
//            make.top.greaterThanOrEqualTo(topImageView.snp.bottom).inset(-8).priority(999)
//            self.descriptionAddressConstraint = make.top.equalTo(descriptionLabel.snp.bottom).inset(-8).priority(1000).constraint
//        }
//
//        hourLineView.snp.makeConstraints { make in
//            make.left.right.equalTo(grid)
//            make.height.equalTo(AddressLineView.height).priority(999)
//            make.bottom.equalTo(grid)
//        }
//    }
//
//    func render(card: SearchCard, delegate: SearchTableViewDelegate) {
//        guard let area: Area = card.decode(name: "area", Area.self) else {
//            return
//        }
//
//        topImageView.render(image: area.images?.get(0))
//        nameLabel.text = area.name
//
//        if let description = area.description {
//            descriptionLabel.text = description
//            let lines = descriptionLabel.countLines(width: SearchAreaClusterHeaderCard.contentWidth)
//            descriptionLabel.numberOfLines = lines
//
//            descriptionAddressConstraint.activate()
//        } else {
//            descriptionAddressConstraint.deactivate()
//            descriptionLabel.text = nil
//        }
//
//        // Address Line
//        if let address = area.location.address, let latLng = area.location.latLng, let total = area.counts?.total {
//            self.addressLineView.address = address
//            self.addressLineView.latLng = latLng
//            self.addressLineView.count = total
//            self.addressLineView.isHidden = false
//        } else {
//            self.addressLineView.isHidden = true
//        }
//
//        // Hour Line
//        if let hours = area.hour, !hours.isEmpty {
//            self.hourLineView.hours = hours
//            self.hourLineView.isHidden = false
//        } else {
//            self.hourLineView.isHidden = true
//        }
//    }
//
//    static func height(card: SearchCard) -> CGFloat {
//        var height: CGFloat = topBottom + topBottom
//        let titleWidth = width - (leftRight + leftRight)
//
//        // Image
//        height += imageSize.height
//
//        guard let area: Area = card.decode(name: "area", Area.self) else {
//            return height
//        }
//
//        // Description
//        if let description = area.description {
//            let lines = UILabel.countLines(font: descriptionFont, text: description, width: titleWidth)
//            height += CGFloat(lines) * ceil(descriptionFont.lineHeight)
//            height += 8
//            height += 8
//        }
//
//        // Address Line
//        if area.location.address != nil, area.location.latLng != nil {
//            height += AddressLineView.height
//        }
//
//        // Hour Line
//        if let hours = area.hour, !hours.isEmpty, area.counts?.total != nil {
//            height += AddressLineView.height
//        }
//
//        return height
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.topImageView.layer.cornerRadius = 3
//    }
//
//    private(set) static var cardId: String = "injected_AreaClusterHeader_20180621"
//
//    fileprivate class AddressLineView: SRCopyableView {
//        static let headerStyle = Style{
//            $0.color = UIColor.black
//            $0.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
//        }
//        static let addressStyle = Style {
//            $0.color = UIColor.black
//            $0.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
//        }
//        static let countStyle = Style {
//            $0.color = UIColor.black
//            $0.alignment = .center
//            $0.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
//        }
//        static let placeStyle = Style {
//            $0.color = UIColor.black
//            $0.alignment = .center
//            $0.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
//        }
//
//        static let height: CGFloat = 52
//        static let rightWidth: CGFloat = 70
//        private let leftLabel: UILabel = {
//            let label = UILabel()
//            label.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
//            label.numberOfLines = 0
//            return label
//        }()
//        private let rightLabel: UILabel = {
//            let label = UILabel()
//            label.numberOfLines = 0
//            label.textAlignment = .center
//            return label
//        }()
//
//        var address: String! {
//            didSet {
//                let attributedText = NSMutableAttributedString()
//                attributedText.append("\("Address".localized())\n".set(style: AddressLineView.headerStyle))
//                attributedText.append(address.set(style: AddressLineView.addressStyle))
//                self.leftLabel.attributedText = attributedText
//            }
//        }
//        var count: Int? {
//            didSet {
//                if let count = self.count {
//                    let attributedText = NSMutableAttributedString()
//                    attributedText.append("\(count)\n".set(style: AddressLineView.countStyle))
//                    attributedText.append("food spots".localized().set(style: AddressLineView.placeStyle))
//                    self.rightLabel.attributedText = attributedText
//                } else {
//                    self.rightLabel.text = nil
//                }
//            }
//        }
//        var latLng: String?
//
//        override var copyableText: String? {
//            return self.address
//        }
//
//        override init(frame: CGRect = .zero) {
//            super.init(frame: frame)
//            self.addSubview(leftLabel)
//            self.addSubview(rightLabel)
//
//            leftLabel.snp.makeConstraints { make in
//                make.left.top.bottom.equalTo(self)
//                make.right.equalTo(self.rightLabel.snp.left).inset(-18)
//            }
//
//            rightLabel.snp.makeConstraints { make in
//                make.right.top.bottom.equalTo(self)
//                make.height.equalTo(AddressLineView.height)
//                make.width.equalTo(AddressLineView.rightWidth)
//            }
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//    }
//
//    fileprivate class HourLineView: UIView {
//        static let openStyle = Style {
//            $0.color = UIColor.secondary500
//            $0.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
//        }
//        static let closeStyle = Style {
//            $0.color = UIColor.primary500
//            $0.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
//        }
//        static let hourStyle = Style {
//            $0.color = UIColor.black
//            $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//        }
//        static let boldStyle = Style {
//            $0.color = UIColor.black
//            $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
//        }
//
//        private let leftLabel: UILabel = {
//            let label = UILabel()
//            label.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
//            label.numberOfLines = 2
//            return label
//        }()
//
//        var hours: [Hour]? {
//            didSet {
//                guard let hours = self.hours else {
//                    self.leftLabel.text = nil
//                    return
//                }
//
//                let attributedText = NSMutableAttributedString()
//                switch hours.isOpen() {
//                case .opening:
//                    attributedText.append("\("Opening Soon".localized())\n".set(style: PlaceBasicBusinessHourCard.openStyle))
//                case .open:
//                    attributedText.append("\("Open Now".localized())\n".set(style: PlaceBasicBusinessHourCard.openStyle))
//                case .closing:
//                    attributedText.append("\("Closing Soon".localized())\n".set(style: PlaceBasicBusinessHourCard.closeStyle))
//                case .closed: fallthrough
//                case .none:
//                    attributedText.append("\("Closed Now".localized())\n".set(style: PlaceBasicBusinessHourCard.closeStyle))
//
//                }
//
//                attributedText.append(hours.grouped.todayDayTimeRange.set(style: PlaceBasicBusinessHourCard.hourStyle))
//                self.leftLabel.attributedText = attributedText
//            }
//        }
//
//        override init(frame: CGRect = .zero) {
//            super.init(frame: frame)
//            self.addSubview(leftLabel)
//
//            leftLabel.snp.makeConstraints { make in
//                make.left.right.top.bottom.equalTo(self)
//            }
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//    }
//}
