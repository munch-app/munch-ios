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
    private let label = UILabel(style: .h2).with(text: "Where")
    private let search = SearchButton()
    private let buttons = LocationButtonGroup()

    private let manager: FilterManager
    private let controller: UIViewController

    init(manager: FilterManager, controller: UIViewController) {
        self.manager = manager
        self.controller = controller
        super.init(style: .default, reuseIdentifier: nil)
        self.selectionStyle = .none

        self.addSubview(label)
        self.addSubview(search)
        self.addSubview(buttons)
        self.addTargets()

        label.snp.makeConstraints { maker in
            maker.left.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(16)
        }

        search.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.centerY.equalTo(label)
        }

        buttons.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(label.snp.bottom).inset(-16)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    func reloadData() {
        let location = manager.searchQuery.filter.location
        self.buttons.reloadData(location: location)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterItemCellLocation {
    func addTargets() {
        for button in buttons.buttons {
            button.addTarget(self, action: #selector(onLocation(for:)), for: .touchUpInside)
        }

        search.addTarget(self, action: #selector(onSearch(for:)), for: .touchUpInside)
    }

    @objc fileprivate func onLocation(for button: LocationButton) {
        switch button.type {
        case .Between:
            break // TODO

        case .Nearby:
            self.manager.select(location: .Nearby)

        case .Anywhere:
            self.manager.select(location: .Anywhere)

        default:
            return
        }
    }

    @objc fileprivate func onSearch(for button: SearchButton) {
        let controller = FilterLocationSearchController(searchQuery: manager.searchQuery) { query in
            if let query = query {
                self.manager.select(searchQuery: query)
            }
        }
        self.controller.present(controller, animated: true)
    }
}

fileprivate class LocationButtonGroup: UIButton {
    fileprivate let first = LocationButton(
            type: SearchQuery.Filter.Location.LocationType.Between,
            label: "EatBetween", image: UIImage(named: "Search-Filter-Location-EatBetween")!
    )
    fileprivate let second = LocationButton(
            type: SearchQuery.Filter.Location.LocationType.Nearby,
            label: "Nearby", image: UIImage(named: "Search-Filter-Location-Nearby")!
    )
    fileprivate let third = LocationButton(
            type: SearchQuery.Filter.Location.LocationType.Anywhere,
            label: "Anywhere", image: UIImage(named: "Search-Filter-Location-Anywhere")!
    )

    fileprivate var buttons: [LocationButton] {
        return [first, second, third]
    }

    required init() {
        super.init(frame: .zero)
        self.addSubview(first)
        self.addSubview(second)
        self.addSubview(third)

        for button in buttons {
            button.snp.makeConstraints { maker in
                maker.height.equalTo(button.snp.width).multipliedBy(0.85)
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

    func reloadData(location: SearchQuery.Filter.Location) {
        for button in buttons {
            button.isSelected = button.type == location.type
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class LocationButton: UIButton {
    let type: SearchQuery.Filter.Location.LocationType
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        return imageView
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    override var isSelected: Bool {
        didSet {
            if isSelected {
                iconView.tintColor = .white
                nameLabel.textColor = .white
                backgroundColor = .primary500
            } else {
                iconView.tintColor = .ba85
                nameLabel.textColor = .ba85
                backgroundColor = .whisper100
            }
        }
    }

    required init(type: SearchQuery.Filter.Location.LocationType, label: String, image: UIImage) {
        self.type = type
        super.init(frame: .zero)
        self.addSubview(iconView)
        self.addSubview(nameLabel)

        self.nameLabel.text = label
        self.iconView.image = image

        iconView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(self)
            maker.bottom.equalTo(nameLabel.snp.top).inset(8)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.bottom.equalTo(self).inset(8)
            maker.height.equalTo(20)
        }

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

fileprivate class SearchButton: UIButton {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "Search-Filter-Location-Search")
        imageView.tintColor = .ba85
        return imageView
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Search"
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(hex: "FCFCFC")
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.ba15.cgColor

        self.addSubview(iconView)
        self.addSubview(nameLabel)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(32)
        }

        iconView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(self).inset(8)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self)
            maker.right.equalTo(self).inset(12)
            maker.left.equalTo(iconView.snp.right).inset(-4)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 3.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO Where Button