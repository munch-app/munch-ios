//
// Created by Fuxing Loh on 27/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import SwiftRichString
import BEMCheckBox
import RangeSeekSlider
import Charts

class DiscoverFilterCellLoading: UITableViewCell {
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

class DiscoverFilterCellDescription: UITableViewCell {
    private let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor(hex: "444444")
        imageView.image = UIImage(named: "Search-Glass")
        return imageView
    }()
    private let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        label.textColor = UIColor(hex: "444444")
        label.textAlignment = .center

        label.numberOfLines = 2
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "Search for any "))
        text.append("Location".set(style: .default { make in
            make.font = FontAttribute(font: .systemFont(ofSize: 16.0, weight: .semibold))
        }))
        text.append(NSAttributedString(string: ", Cuisine, Food or Amenities"))
        label.attributedText = text
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(label)
        self.addSubview(icon)

        icon.snp.makeConstraints { make in
            make.left.equalTo(self).inset(35)
            make.top.equalTo(self).inset(18)
            make.bottom.equalTo(self).inset(18)

            make.height.width.equalTo(40)
        }

        label.snp.makeConstraints { make in
            make.top.bottom.equalTo(icon)
            make.right.equalTo(self).inset(35)
            make.left.equalTo(icon.snp.right).inset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "DiscoverFilterCellDescription"
    }
}

class DiscoverFilterCellHeader: UITableViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(hex: "434343")
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.equalTo(self).inset(34)
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
        return "DiscoverFilterCellHeader"
    }
}

class DiscoverFilterCellHeaderLocation: UITableViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.backgroundColor = .white
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(hex: "434343")
        return label
    }()
    private let moreButton: UIButton = {
        let button = UIButton()
        button.setTitle("See All", for: .normal)
        button.setTitleColor(UIColor.primary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)

        button.contentHorizontalAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        button.isUserInteractionEnabled = false
        return button
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label)
        self.addSubview(moreButton)

        label.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)

            make.top.equalTo(self).inset(18)
            make.bottom.equalTo(self).inset(14)
        }

        moreButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)

            make.top.bottom.equalTo(label)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "DiscoverFilterCellHeaderLocation"
    }
}

class DiscoverFilterCellNoResult: UITableViewCell {
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

class DiscoverFilterCellLocation: UITableViewCell {
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

    var locations: [DiscoverFilterLocation]!
    private var isHookSet: Bool = false

    var controller: DiscoverFilterController! {
        didSet {
            if !isHookSet {
                controller.manager.addUpdateHook { query in
                    self.collectionView.setContentOffset(.zero, animated: false)
                    self.collectionView.reloadData()
                }
                isHookSet = true
            }
        }
    }

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

    func render(locations: [DiscoverFilterLocation], controller: DiscoverFilterController) {
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

extension DiscoverFilterCellLocation: UICollectionViewDataSource, UICollectionViewDelegate {
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
            controller.manager.select(location: DiscoverFilterControllerManager.anywhere, save: false)
        case let .location(location):
            controller.manager.select(location: location)
        case let .container(container):
            controller.manager.select(container: container)
        }
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

class DiscoverFilterCellPriceRange: UITableViewCell, RangeSeekSliderDelegate {
    private let loadingIndicator: UIView = {
        let view = UIView()

        let lineView = ShimmerView(color: UIColor(hex: "D0D0D0"))
        lineView.shimmeringAnimationOpacity = 0.8
        lineView.shimmeringOpacity = 0.3
        lineView.shimmeringSpeed = 100

        let priceButton = PriceButtonShimmerView()
        view.addSubview(lineView)
        view.addSubview(priceButton)

        lineView.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(priceButton.snp.top).inset(-24).priority(999)
            make.height.equalTo(3)
        }

        priceButton.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(view)
        }

        return view
    }()
    private let containerView: UIView = {
        return UIView()
    }()
    private let chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.dragEnabled = false
        chartView.chartDescription?.enabled = false

        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.drawMarkers = false
        chartView.xAxis.enabled = false
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.noDataText = ""
        return chartView
    }()

    private let priceButtons = PriceButtonGroup()
    private let priceSlider = PriceRangeSlider()

    private var isHookSet: Bool = false
    private var locationName: String?
    private var filterPriceRange: FilterPriceRange?

    var controller: DiscoverFilterController! {
        didSet {
            if !isHookSet {
                self.reload()
                controller.manager.addUpdateHook { query in
                    self.reload()
                }
                isHookSet = true
            }
        }
    }

    var isLoading: Bool = true {
        didSet {
            priceSlider.isHidden = isLoading
            priceButtons.isHidden = isLoading
            loadingIndicator.isHidden = !isLoading
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)
        containerView.addSubview(chartView)
        containerView.addSubview(priceSlider)
        containerView.addSubview(priceButtons)
        containerView.addSubview(loadingIndicator)

        priceButtons.cheapButton.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        priceButtons.averageButton.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        priceButtons.expensiveButton.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        priceSlider.delegate = self

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(14)
            make.bottom.equalTo(self)
        }

        priceSlider.snp.makeConstraints { make in
            make.left.right.equalTo(containerView).inset(-8).priority(999)
            make.bottom.equalTo(priceButtons.snp.top).inset(6).priority(999)
        }

        priceButtons.snp.makeConstraints { make in
            make.left.right.equalTo(containerView)
            make.bottom.equalTo(containerView).inset(3)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
        }

        chartView.snp.makeConstraints { make in
            make.height.equalTo(100)
            make.left.right.equalTo(containerView)

            make.top.equalTo(containerView).inset(-30)
            make.bottom.equalTo(priceSlider.snp.bottom).inset(20)
        }

        self.layoutIfNeeded()
        self.isLoading = true
    }

    fileprivate func reload() {
        let locationName = controller.manager.getLocationName()
        if locationName == self.locationName {
            self.updateSelected()
            return
        }

        self.filterPriceRange = nil
        self.isLoading = true
        self.locationName = locationName
        self.chartView.clear()

        let deadline = DispatchTime.now() + 0.75
        controller.manager.getPriceRange { metaJSON, filterPriceRange in
            self.filterPriceRange = filterPriceRange

            if metaJSON.isOk(), let filterPriceRange = filterPriceRange {
                DispatchQueue.main.asyncAfter(deadline: deadline) {
                    let min = filterPriceRange.all.minRounded
                    let max = filterPriceRange.all.maxRounded
                    self.priceSlider.minValue = CGFloat(min)
                    self.priceSlider.maxValue = CGFloat(max)

                    self.chartView.data = LineChartData(dataSets: self.groupInto(filterPriceRange: filterPriceRange))

                    self.priceSlider.enableStep = false
                    self.updateSelected()
                    self.isLoading = false
                }
            } else {
                self.controller.present(metaJSON.createAlert(), animated: true)
            }
        }
    }

    private func groupInto(filterPriceRange: FilterPriceRange) -> [LineChartDataSet] {
        var frequency = filterPriceRange.frequency

        func putRequired(value: Double, num: Int = 0) {
            if !frequency.contains(where: { $0.key == "\(value)" }) {
                frequency[String(value)] = num
            }
        }

        putRequired(value: filterPriceRange.all.minRounded)
        putRequired(value: filterPriceRange.all.maxRounded)
//        putRequired(value: filterPriceRange.cheap.min)
//        putRequired(value: filterPriceRange.cheap.max)
//        putRequired(value: filterPriceRange.average.min)
//        putRequired(value: filterPriceRange.average.max)
//        putRequired(value: filterPriceRange.expensive.min)
//        putRequired(value: filterPriceRange.expensive.max)

        let sorted = frequency
                .map({ tuple -> (Double, Double) in
                    (Double(tuple.key) ?? 0, Double(tuple.value))
                })
                .sorted(by: { (v: (Double, Double), v1: (Double, Double)) in
                    v.0 < v1.0
                })

        func createGroup(min: Double, max: Double) -> [ChartDataEntry] {
            return sorted
                    .filter({ keyValue in
                        min <= keyValue.0 && max >= keyValue.0
                    })
                    .map({ (tuple: (Double, Double)) -> ChartDataEntry in ChartDataEntry(x: Double(tuple.0), y: Double(tuple.1)) })
        }

        func createSet(values: [ChartDataEntry], color: UIColor) -> LineChartDataSet {
            let set = LineChartDataSet(values: values, label: nil)
            set.drawValuesEnabled = false
            set.mode = .cubicBezier
            set.cubicIntensity = 0.2
            set.drawCirclesEnabled = false
            set.circleRadius = 10
            set.lineWidth = 0

            set.drawFilledEnabled = true
            set.fillColor = UIColor(hex: "E0E0E0")
            set.fillAlpha = 1.0
            return set
        }

        return [
            createSet(values: createGroup(min: filterPriceRange.all.minRounded, max: filterPriceRange.all.maxRounded), color: PriceButtonGroup.colors[0]),
//            createSet(values: createGroup(min: filterPriceRange.average.min, max: filterPriceRange.average.max), color: PriceButtonGroup.colors[1]),
//            createSet(values: createGroup(min: filterPriceRange.expensive.min, max: filterPriceRange.expensive.maxRounded), color: PriceButtonGroup.colors[2])
        ]
    }

    @objc fileprivate func onPriceButton(for button: UIButton) {
        if let filterPriceRange = filterPriceRange, let name = button.title(for: .normal) {
            switch name {
            case "$":
                controller.manager.select(price: name, min: filterPriceRange.cheap.min, max: filterPriceRange.cheap.max)
            case "$$":
                controller.manager.select(price: name, min: filterPriceRange.average.min, max: filterPriceRange.average.max)
            case "$$$":
                controller.manager.select(price: name, min: filterPriceRange.expensive.min, max: filterPriceRange.expensive.max)
            default:break
            }

            self.updateSelected()
        } else {
            controller.manager.select(price: nil, min: nil, max: nil)
        }
    }

    func didEndTouches(in slider: RangeSeekSlider) {
        let min = Double(priceSlider.selectedMinValue)
        let max = Double(priceSlider.selectedMaxValue)
        priceButtons.select(name: nil)


        if filterPriceRange?.all.min == min && filterPriceRange?.all.max == max {
            controller.manager.select(price: nil, min: nil, max: nil)
        } else {
            controller.manager.select(price: nil, min: min, max: max)
        }
    }

    func didStartTouches(in slider: RangeSeekSlider) {
        slider.enableStep = true
    }

    private func updateSelected() {
        if let filterPriceRange = filterPriceRange {
            priceButtons.select(name: controller.manager.searchQuery.filter.price.name)
            let price = self.controller.manager.searchQuery.filter.price

            self.priceSlider.selectedMinValue = CGFloat(price.min ?? filterPriceRange.all.minRounded)
            self.priceSlider.selectedMaxValue = CGFloat(price.max ?? filterPriceRange.all.maxRounded)
            priceSlider.setNeedsLayout()
        }
    }

    class PriceRangeSlider: RangeSeekSlider {
        override func setupStyle() {
            colorBetweenHandles = .primary200
            handleColor = .primary600
            tintColor = UIColor(hex: "CCCCCC")
            minLabelColor = UIColor.black.withAlphaComponent(0.75)
            maxLabelColor = UIColor.black.withAlphaComponent(0.75)
            minLabelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            maxLabelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)

            numberFormatter.numberStyle = .currency

            handleDiameter = 18
            selectedHandleDiameterMultiplier = 1.3
            lineHeight = 3.0

            minDistance = 5

            enableStep = false
            step = 5.0
        }
    }

    class PriceButtonGroup: UIButton {
        static let colors = [UIColor(hex: "F0F0F0"), UIColor(hex: "F0F0F0"), UIColor(hex: "F0F0F0")]
        fileprivate let cheapButton: UIButton = {
            let button = UIButton()
            button.backgroundColor = colors[0]
            button.setTitle("$", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
            return button
        }()
        fileprivate let averageButton: UIButton = {
            let button = UIButton()
            button.backgroundColor = colors[1]
            button.setTitle("$$", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
            return button
        }()
        fileprivate let expensiveButton: UIButton = {
            let button = UIButton()
            button.backgroundColor = colors[2]
            button.setTitle("$$$", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
            return button
        }()
        fileprivate var buttons: [UIButton] {
            return [cheapButton, averageButton, expensiveButton]
        }

        required init() {
            super.init(frame: .zero)
            self.addSubview(cheapButton)
            self.addSubview(averageButton)
            self.addSubview(expensiveButton)

            cheapButton.snp.makeConstraints {
                make in
                make.left.equalTo(self)
                make.right.equalTo(averageButton.snp.left).inset(-18)
                make.width.equalTo(averageButton.snp.width)
                make.width.equalTo(expensiveButton.snp.width)
                make.height.equalTo(32)
                make.top.bottom.equalTo(self)
            }

            averageButton.snp.makeConstraints {
                make in
                make.left.equalTo(cheapButton.snp.right).inset(-18)
                make.right.equalTo(expensiveButton.snp.left).inset(-18)
                make.width.equalTo(cheapButton.snp.width)
                make.width.equalTo(expensiveButton.snp.width)
                make.top.bottom.equalTo(self)
            }

            expensiveButton.snp.makeConstraints {
                make in
                make.left.equalTo(averageButton.snp.right).inset(-18)
                make.right.equalTo(self)
                make.width.equalTo(cheapButton.snp.width)
                make.width.equalTo(averageButton.snp.width)
                make.top.bottom.equalTo(self)
            }
        }

        fileprivate func select(name: String?) {
            for (index, button) in buttons.enumerated() {
                if (button.title(for: .normal) == name) {
                    button.backgroundColor = .primary400
                    button.setTitleColor(.white, for: .normal)
                } else {
                    button.backgroundColor = PriceButtonGroup.colors[index]
                    button.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            cheapButton.layer.cornerRadius = 3.0
            averageButton.layer.cornerRadius = 3.0
            expensiveButton.layer.cornerRadius = 3.0
            cheapButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
            averageButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
            expensiveButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class PriceButtonShimmerView: UIView {
        fileprivate let cheapButton = ShimmerView(color: UIColor(hex: "E6E6E6"))
        fileprivate let averageButton = ShimmerView(color: UIColor(hex: "E6E6E6"))
        fileprivate let expensiveButton = ShimmerView(color: UIColor(hex: "E6E6E6"))

        required init() {
            super.init(frame: .zero)
            self.addSubview(cheapButton)
            self.addSubview(averageButton)
            self.addSubview(expensiveButton)

            cheapButton.snp.makeConstraints {
                make in
                make.left.equalTo(self)
                make.right.equalTo(averageButton.snp.left).inset(-18)
                make.width.equalTo(averageButton.snp.width)
                make.width.equalTo(expensiveButton.snp.width)
                make.height.equalTo(32)
                make.top.bottom.equalTo(self)
            }

            averageButton.snp.makeConstraints { make in
                make.left.equalTo(cheapButton.snp.right).inset(-18)
                make.right.equalTo(expensiveButton.snp.left).inset(-18)
                make.width.equalTo(cheapButton.snp.width)
                make.width.equalTo(expensiveButton.snp.width)
                make.top.bottom.equalTo(self)
            }

            expensiveButton.snp.makeConstraints {
                make in
                make.left.equalTo(averageButton.snp.right).inset(-18)
                make.right.equalTo(self)
                make.width.equalTo(cheapButton.snp.width)
                make.width.equalTo(averageButton.snp.width)
                make.top.bottom.equalTo(self)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            cheapButton.contentView.layer.cornerRadius = 3.0
            averageButton.contentView.layer.cornerRadius = 3.0
            expensiveButton.contentView.layer.cornerRadius = 3.0
            cheapButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
            averageButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
            expensiveButton.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchSuggestCellPriceRange"
    }
}

class DiscoverFilterCellTiming: UITableViewCell {
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16 // LeftRight

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = .zero
        collectionView.register(SearchSuggestCellTimingGridCellOpenNow.self, forCellWithReuseIdentifier: "SearchSuggestCellTimingGridCellOpenNow")
        collectionView.register(SearchSuggestCellTimingGridCellTitle.self, forCellWithReuseIdentifier: "SearchSuggestCellTimingGridCellTitle")
        return collectionView
    }()

    var controller: DiscoverFilterController!
    var timings: [DiscoverFilterTiming]!

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

    func render(timings: [DiscoverFilterTiming], controller: DiscoverFilterController) {
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

    class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
        override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            let attributes = super.layoutAttributesForElements(in: rect)

            var leftMargin = sectionInset.left
            var maxY: CGFloat = -1.0
            attributes?.forEach { layoutAttribute in
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = sectionInset.left
                }

                layoutAttribute.frame.origin.x = leftMargin

                leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
                maxY = max(layoutAttribute.frame.maxY, maxY)
            }

            return attributes
        }
    }
}

extension DiscoverFilterCellTiming: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch timings[indexPath.row] {
        case .now:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SearchSuggestCellTimingGridCellOpenNow", for: indexPath)
        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SearchSuggestCellTimingGridCellTitle", for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch timings[indexPath.row] {
        case .now:
            let cell = cell as! SearchSuggestCellTimingGridCellOpenNow
            let selected = controller.manager.isSelected(hour: "Open Now")
            cell.render(text: "Open Now", selected: selected)
        case .breakfast:
            let cell = cell as! SearchSuggestCellTimingGridCellTitle
            let selected = controller.manager.isSelected(hour: "Breakfast")
            cell.render(text: "Breakfast", selected: selected)
        case .lunch:
            let cell = cell as! SearchSuggestCellTimingGridCellTitle
            let selected = controller.manager.isSelected(hour: "Lunch")
            cell.render(text: "Lunch", selected: selected)
        case .dinner:
            let cell = cell as! SearchSuggestCellTimingGridCellTitle
            let selected = controller.manager.isSelected(hour: "Dinner")
            cell.render(text: "Dinner", selected: selected)
        case .supper:
            let cell = cell as! SearchSuggestCellTimingGridCellTitle
            let selected = controller.manager.isSelected(hour: "Supper")
            cell.render(text: "Supper", selected: selected)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch timings[indexPath.row] {
        case .now:
            return CGSize(width: 106 + 20, height: 36)
        default:
            return CGSize(width: 100, height: 36)
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
    }

    fileprivate class SearchSuggestCellTimingGridCellOpenNow: UICollectionViewCell {
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
            nameLabel.text = "Open Now"
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

    fileprivate class SearchSuggestCellTimingGridCellTitle: UICollectionViewCell {
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
                containerView.backgroundColor = .primary400
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
}

class DiscoverFilterCellTag: UITableViewCell {
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
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hex: "444444")
        return label
    }()
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()

    private let shimmerView: ShimmerView = {
        let view = ShimmerView(color: UIColor(hex: "E6E6E6"))
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(shimmerView)
        self.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(checkButton)
        containerView.addSubview(sizeLabel)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(2)
        }

        shimmerView.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
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

        sizeLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(containerView).inset(12)
            make.right.equalTo(checkButton.snp.left).inset(-10)
        }
        self.layoutIfNeeded()
    }

    func render(title: String, selected: Bool, count: FilterCount?) {
        if let count = count {
            let size = count.tags[title.lowercased(), default: 0]
            if size > 0 {
                sizeLabel.text = DiscoverFilterBottomView.countTitle(count: size, prefix: "", postfix: "")
                sizeLabel.textColor = UIColor(hex: "444444")
                checkButton.tintColor = UIColor(hex: "444444")
            } else {
                sizeLabel.text = "0"
                sizeLabel.textColor = UIColor(hex: "CCCCCC")
                checkButton.tintColor = UIColor(hex: "CCCCCC")
            }
            containerView.isHidden = false
            shimmerView.isShimmering = false
            shimmerView.isHidden = true
        } else {
            containerView.isHidden = true
            shimmerView.isShimmering = true
            shimmerView.isHidden = false
        }

        titleLabel.text = title
        checkButton.setOn(selected, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 3
        containerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)

        shimmerView.layer.cornerRadius = 3
        shimmerView.shadow(width: 1, height: 1, radius: 2, opacity: 0.4)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchSuggestCellTag"
    }
}

class DiscoverFilterCellTagMore: UITableViewCell {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.text = "Show All"
        titleLabel.textColor = UIColor.primary
        return titleLabel
    }()
    private let moreImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Right-Arrow")
        imageView.tintColor = UIColor(hex: "333333")
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.isHidden = true
        return imageView
    }()
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(moreImageView)

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(2)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(containerView).inset(12)
            make.left.equalTo(containerView).inset(18)
            make.right.equalTo(moreImageView.snp.left).inset(-12)
        }

        moreImageView.snp.makeConstraints { make in
            make.top.bottom.equalTo(containerView).inset(10)
            make.right.equalTo(containerView).inset(22)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "SearchSuggestCellTagMore"
    }
}

class DiscoverFilterCellHeaderCategory: UITableViewCell {
    private let containerView = UIView()
    private let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Cuisine", "Establishment", "Others"])
        control.tintColor = UIColor.primary500
        control.selectedSegmentIndex = 0
        return control
    }()

    var controller: DiscoverFilterController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(segmentControl)

        segmentControl.addTarget(self, action: #selector(actionSelect(_:)), for: .valueChanged)
        segmentControl.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(self).inset(44)
            make.bottom.equalTo(self).inset(20)
        }
    }

    @objc fileprivate func actionSelect(_ control: UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0:
            controller.manager.select(category: .cuisine)
        case 1:
            controller.manager.select(category: .establishment)
        case 2:
            controller.manager.select(category: .others)
        default: return
        }
        self.controller.tableView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "DiscoverFilterCellHeaderCategory"
    }
}

class DiscoverFilterCellSmallLocation: UITableViewCell {

    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = .black
        return titleLabel
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self).inset(10)
            make.left.equalTo(self).inset(24)
            make.right.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class var id: String {
        return "DiscoverFilterCellSmallLocation"
    }
}