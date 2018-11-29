//
// Created by Fuxing Loh on 22/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Localize_Swift

import SnapKit
import SwiftRichString
import BEMCheckBox
import RangeSeekSlider
import Charts

import FirebaseAnalytics

fileprivate class SearchFilterHeader: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(hex: "434343")
        return label
    }()

    var text: String? {
        get {
            return label.text
        }
        set(value) {
            label.text = value
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.equalTo(self).inset(14)
            make.bottom.equalTo(self).inset(14)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchFilterCellLocation: UITableViewCell {
    private let titleLabel: SearchFilterHeader = {
        let header = SearchFilterHeader()
        header.text = "Location".localized()
        return header
    }()
    private let moreButton: UIButton = {
        let button = UIButton()
        button.setTitle("See All".localized(), for: .normal)
        button.setTitleColor(UIColor.primary500, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)

        button.contentHorizontalAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()

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
        collectionView.register(SearchFilterCellLocationGridCell.self, forCellWithReuseIdentifier: "SearchFilterCellLocationGridCell")
        return collectionView
    }()

    let manager: SearchFilterManager
    let controller: SearchFilterController

    var locations = [SearchFilterType.Location]()

    init(manager: SearchFilterManager, controller: SearchFilterController) {
        self.manager = manager
        self.controller = controller
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(moreButton)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.moreButton.addTarget(self, action: #selector(action(more:)), for: .touchUpInside)

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.top.equalTo(self).inset(20)
        }

        moreButton.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(titleLabel)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).inset(1)
            make.left.right.equalTo(self)
            make.height.equalTo(94)
            make.bottom.equalTo(self).inset(20)
        }
    }

    func render(locations: [SearchFilterType.Location]) {
        self.locations = locations
        self.collectionView.reloadData()
    }

    @objc func action(more: Any) {
        self.controller.goTo(.location)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchFilterCellLocation: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchFilterCellLocationGridCell", for: indexPath) as! SearchFilterCellLocationGridCell

        switch locations[indexPath.row] {
        case .nearby(let selected):
            cell.render(text: "Nearby".localized(), image: UIImage(named: "Search-Location-Nearby"), selected: selected)

        case .anywhere(_, let selected):
            cell.render(text: "Anywhere".localized(), image: UIImage(named: "Search-Location-Anywhere"), selected: selected)

        case .area(let area, let selected):
            cell.render(text: area.name, image: UIImage(named: "Search-Location-Pin"), selected: selected)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch locations[indexPath.row] {
        case .nearby:
            manager.select(area: nil, persist: false)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemCategory: "apply_location_nearby" as NSObject
            ])

        case .anywhere(let area, _):
            manager.select(area: area, persist: false)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemCategory: "apply_location_anywhere" as NSObject
            ])

        case .area(let area, _):
            manager.select(area: area, persist: true)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemID: "location-\(area.areaId ?? "")" as NSObject,
                AnalyticsParameterItemCategory: "apply_location" as NSObject
            ])

        }
    }

    fileprivate class SearchFilterCellLocationGridCell: UICollectionViewCell {
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

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class SearchFilterCellTiming: UITableViewCell {
    private let titleLabel: SearchFilterHeader = {
        let header = SearchFilterHeader()
        header.text = "Timing".localized()
        return header
    }()
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
        collectionView.register(SearchFilterCellTimingOpenNowCell.self, forCellWithReuseIdentifier: String(describing: SearchFilterCellTimingOpenNowCell.self))
        collectionView.register(SearchFilterCellTimingNameCell.self, forCellWithReuseIdentifier: String(describing: SearchFilterCellTimingNameCell.self))
        return collectionView
    }()

    let manager: SearchFilterManager
    let controller: SearchFilterController

    var timings = [SearchFilterType.Timing]()

    init(manager: SearchFilterManager, controller: SearchFilterController) {
        self.manager = manager
        self.controller = controller
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.left.top.equalTo(self)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).inset(1)
            make.left.right.equalTo(self)
            make.height.equalTo(40).priority(999)
            make.bottom.equalTo(self)
        }
    }

    func render(timings: [SearchFilterType.Timing]) {
        self.timings = timings
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchFilterCellTiming: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchFilterCellTimingOpenNowCell.self), for: indexPath)
        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchFilterCellTimingNameCell.self), for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch timings[indexPath.row] {
        case let .now(name, selected):
            let cell = cell as! SearchFilterCellTimingOpenNowCell
            cell.render(text: name, selected: selected)

        case let .name(name, selected):
            let cell = cell as! SearchFilterCellTimingNameCell
            cell.render(text: name, selected: selected)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let timing = timings[indexPath.row]
        manager.select(timing: timing)

        switch timing {
        case let .now(name, _):
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemID: "timing-" + name as NSObject,
                AnalyticsParameterItemCategory: "apply_hour" as NSObject
            ])
        case let .name(name, _):
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemID: "timing-" + name as NSObject,
                AnalyticsParameterItemCategory: "apply_hour" as NSObject
            ])
        }
    }

    fileprivate class SearchFilterCellTimingOpenNowCell: UICollectionViewCell {
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

    fileprivate class SearchFilterCellTimingNameCell: UICollectionViewCell {
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

class SearchFilterCellPriceRange: UITableViewCell, RangeSeekSliderDelegate {
    private let titleLabel: SearchFilterHeader = {
        let header = SearchFilterHeader()
        header.text = "Price Range".localized()
        return header
    }()
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

    private var filterPriceGraph: FilterPriceGraph?

    let manager: SearchFilterManager
    let controller: SearchFilterController

    init(manager: SearchFilterManager, controller: SearchFilterController) {
        self.manager = manager
        self.controller = controller
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none
        self.addSubview(titleLabel)
        self.addSubview(containerView)

        containerView.addSubview(chartView)
        containerView.addSubview(priceSlider)
        containerView.addSubview(priceButtons)
        containerView.addSubview(loadingIndicator)

        priceButtons.cheapButton.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        priceButtons.averageButton.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        priceButtons.expensiveButton.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        priceSlider.delegate = self

        titleLabel.snp.makeConstraints { make in
            make.left.top.equalTo(self)
        }

        containerView.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.equalTo(titleLabel.snp.bottom).inset(-14)
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
    }

    func render(filterPriceGraph: FilterPriceGraph?) {
        self.chartView.clear()
        self.filterPriceGraph = filterPriceGraph

        if let filterPriceGraph = filterPriceGraph {
            self.priceSlider.minValue = CGFloat(filterPriceGraph.min)
            self.priceSlider.maxValue = CGFloat(filterPriceGraph.max)

            self.chartView.data = LineChartData(dataSets: self.groupInto(filterPriceGraph: filterPriceGraph))
            self.priceSlider.enableStep = false
            self.updateSelected()

            priceSlider.isHidden = false
            priceButtons.isHidden = false
            loadingIndicator.isHidden = true
        } else {
            priceSlider.isHidden = true
            priceButtons.isHidden = true
            loadingIndicator.isHidden = false
        }
    }

    private func groupInto(filterPriceGraph: FilterPriceGraph) -> [LineChartDataSet] {
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

        let entry = filterPriceGraph.sorted
                .map({ (tuple: (Double, Int)) in ChartDataEntry(x: tuple.0, y: Double(tuple.1)) })

        return [
            createSet(values: entry, color: PriceButtonGroup.colors[0]),
        ]
    }

    @objc fileprivate func onPriceButton(for button: UIButton) {
        if let filterPriceGraph = filterPriceGraph, let name = button.title(for: .normal) {
            switch name {
            case "$":
                manager.select(price: name, min: filterPriceGraph.f0, max: filterPriceGraph.f30)
                Analytics.logEvent("search_filter_action", parameters: [
                    AnalyticsParameterItemID: "price-low" as NSObject,
                    AnalyticsParameterItemCategory: "apply_price" as NSObject
                ])

            case "$$":
                manager.select(price: name, min: filterPriceGraph.f30, max: filterPriceGraph.f70)
                Analytics.logEvent("filter_action", parameters: [
                    AnalyticsParameterItemID: "price-med" as NSObject,
                    AnalyticsParameterItemCategory: "apply_price" as NSObject
                ])

            case "$$$":
                manager.select(price: name, min: filterPriceGraph.f70, max: filterPriceGraph.f100)
                Analytics.logEvent("filter_action", parameters: [
                    AnalyticsParameterItemID: "price-high" as NSObject,
                    AnalyticsParameterItemCategory: "apply_price" as NSObject
                ])

            default:break
            }

            self.updateSelected()
        } else {
            manager.resetPrice()
        }
    }

    func didEndTouches(in slider: RangeSeekSlider) {
        let min = Double(priceSlider.selectedMinValue)
        let max = Double(priceSlider.selectedMaxValue)
        priceButtons.select(name: nil)

        if filterPriceGraph?.min == min && filterPriceGraph?.max == max {
            manager.resetPrice()
        } else {
            manager.select(price: nil, min: min, max: max)
        }

        Analytics.logEvent("search_filter_action", parameters: [
            "min": min,
            "max": max,
            AnalyticsParameterItemID: "price-range" as NSObject,
            AnalyticsParameterItemCategory: "apply_price" as NSObject
        ])
    }

    func didStartTouches(in slider: RangeSeekSlider) {
        slider.enableStep = true
    }

    private func updateSelected() {
        if let filterPriceRange = self.filterPriceGraph {
            let price = self.manager.searchQuery.filter.price
            priceButtons.select(name: price.name)

            self.priceSlider.selectedMinValue = CGFloat(price.min ?? filterPriceRange.min)
            self.priceSlider.selectedMaxValue = CGFloat(price.max ?? filterPriceRange.max)
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
}

class SearchFilterCellTagCategory: UITableViewCell {
    private let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Cuisine", "Establishment", "Amenities"])
        control.tintColor = UIColor.primary500
        control.selectedSegmentIndex = 0
        return control
    }()

    let manager: SearchFilterManager
    let controller: SearchFilterController

    init(manager: SearchFilterManager, controller: SearchFilterController) {
        self.manager = manager
        self.controller = controller
        super.init(style: .default, reuseIdentifier: nil)
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
            manager.select(category: .cuisine)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemID: "category-cuisine" as NSObject,
                AnalyticsParameterItemCategory: "apply_category" as NSObject
            ])

        case 1:
            manager.select(category: .establishment)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemID: "category-establishment" as NSObject,
                AnalyticsParameterItemCategory: "apply_category" as NSObject
            ])

        case 2:
            manager.select(category: .amenities)
            Analytics.logEvent("search_filter_action", parameters: [
                AnalyticsParameterItemID: "category-amenities" as NSObject,
                AnalyticsParameterItemCategory: "apply_category" as NSObject
            ])

        default: return
        }
    }

    func render(category: SearchFilterType.Category) {

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchFilterCellTagMore: UITableViewCell {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.text = "Show All"
        titleLabel.textColor = UIColor.primary500
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
}

class SearchFilterCellTag: UITableViewCell {
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
        checkButton.onTintColor = .primary500
        checkButton.onFillColor = .primary500
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

    func render(title: String, count: Int?, selected: Bool) {
        if let count = count {
            if count > 0 {
                sizeLabel.text = FilterCount.countTitle(count: count, prefix: "", postfix: "")
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
}