//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString
import Localize_Swift

import RangeSeekSlider

class FilterItemCellPrice: UITableViewCell, RangeSeekSliderDelegate {
    private let label = UILabel(style: .h2).with(text: "Price")
    private let subLabel = UILabel(style: .h5).with(text: "Price Per Person")
    private let buttons = PriceButtonGroup()
    private let slider = PriceRangeSlider()

    private let manager: FilterManager

    init(manager: FilterManager) {
        self.manager = manager
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none

        self.addSubview(label)
        self.addSubview(subLabel)
        self.addSubview(buttons)
        self.addSubview(slider)
        self.addTargets()

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(16)
        }

        buttons.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(label.snp.bottom).inset(-16)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(buttons.snp.bottom).inset(-24)
        }

        slider.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(16)
            maker.top.equalTo(subLabel.snp.bottom).inset(-16)
            maker.bottom.equalTo(self).inset(8)
        }
    }

    func reloadData() {
        self.buttons.reloadData(searchQuery: manager.searchQuery)
        guard let graph = manager.result?.priceGraph else {
            return
        }

        let price = manager.searchQuery.filter.price

        slider.minValue = CGFloat(graph.min)
        slider.maxValue = CGFloat(graph.max)

        if let min = price?.min {
            slider.selectedMinValue = CGFloat(min < graph.min ? graph.min : min)
        } else {
            slider.selectedMinValue = CGFloat(graph.min)
        }

        if let max = price?.max {
            slider.selectedMaxValue = CGFloat(graph.max < max ? graph.max : max)
        } else {
            slider.selectedMaxValue = CGFloat(graph.max)
        }

        slider.setNeedsLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterItemCellPrice {
    func addTargets() {
        self.slider.delegate = self
        for button in buttons.buttons {
            button.addTarget(self, action: #selector(onPriceButton(for:)), for: .touchUpInside)
        }
    }

    @objc fileprivate func onPriceButton(for button: UIButton) {
        guard let ranges = manager.result?.priceGraph?.ranges,
              let name = button.title(for: .normal),
              let range = ranges[name] else {
            return
        }

        let price = SearchQuery.Filter.Price(name: name, min: range.min, max: range.max)
        if manager.isSelected(price: price) {
            manager.select(price: nil)
        } else {
            manager.select(price: price)
        }
    }

    func didEndTouches(in slider: RangeSeekSlider) {
        let min = Double(slider.selectedMinValue)
        let max = Double(slider.selectedMaxValue)
        let price = SearchQuery.Filter.Price(name: nil, min: min, max: max)

        self.manager.select(price: price)
    }

    func didStartTouches(in slider: RangeSeekSlider) {
        slider.enableStep = true
    }
}

fileprivate class PriceRangeSlider: RangeSeekSlider {
    override func setupStyle() {
        colorBetweenHandles = .primary300
        handleColor = .primary700
        tintColor = UIColor(hex: "CCCCCC")
        minLabelColor = UIColor.ba85
        maxLabelColor = UIColor.ba85
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

fileprivate class PriceButtonGroup: UIButton {
    fileprivate let first = PriceButton(label: "$")
    fileprivate let second = PriceButton(label: "$$")
    fileprivate let third = PriceButton(label: "$$$")

    fileprivate var buttons: [PriceButton] {
        return [first, second, third]
    }

    required init() {
        super.init(frame: .zero)
        self.addSubview(first)
        self.addSubview(second)
        self.addSubview(third)

        for button in buttons {
            button.snp.makeConstraints { maker in
                maker.height.equalTo(32)
                maker.top.bottom.equalTo(self)

                if button != first {
                    maker.width.equalTo(first.snp.width)
                }
                if button != second {
                    maker.width.equalTo(second.snp.width)
                }
                if button != third {
                    maker.width.equalTo(third.snp.width)
                }
            }
        }

        first.snp.makeConstraints { maker in
            maker.left.equalTo(self)
            maker.right.equalTo(second.snp.left).inset(-18)
        }

        second.snp.makeConstraints { maker in
            maker.left.equalTo(first.snp.right).inset(-18)
            maker.right.equalTo(third.snp.left).inset(-18)
        }

        third.snp.makeConstraints { maker in
            maker.left.equalTo(second.snp.right).inset(-18)
            maker.right.equalTo(self)
        }
    }

    func reloadData(searchQuery: SearchQuery) {
        let selected = searchQuery.filter.price?.name
        for button in buttons {
            button.isSelected = button.title(for: .normal) == selected
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class PriceButton: UIButton {
    override var isSelected: Bool {
        didSet {
            if isSelected {
                setTitleColor(.white, for: .normal)
                backgroundColor = .primary500
            } else {
                setTitleColor(.ba85, for: .normal)
                backgroundColor = .peach100
            }
        }
    }

    required init(label: String) {
        super.init(frame: .zero)
        titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        setTitle(label, for: .normal)

        self.isSelected = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 3.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
