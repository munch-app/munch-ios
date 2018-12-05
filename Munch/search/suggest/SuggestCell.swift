//
// Created by Fuxing Loh on 25/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SwiftRichString

import FirebaseAnalytics

class SuggestCellAssumption: UITableViewCell {
    private let tagTokenConfig = TagTokenConfig()
    private let textTokenConfig = TextTokenConfig()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Suggest-Assumption")
        imageView.tintColor = .ba75
        return imageView
    }()
    private let tagView = MunchTagView(extends: true)
    private let separator = SeparatorLine()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(iconView)
        self.addSubview(tagView)
        self.addSubview(separator)

        iconView.snp.makeConstraints { maker in
            maker.left.equalTo(self).inset(24)
            maker.width.height.equalTo(24)
            maker.centerY.equalTo(self)
        }

        tagView.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.left.equalTo(iconView.snp.right).inset(-16)
            maker.height.equalTo(30)
            maker.top.bottom.equalTo(self).inset(16)
        }

        separator.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.bottom.equalTo(self)
        }
    }

    func render(result: AssumptionQueryResult) {
        self.tagView.removeAll()
        for token in result.tokens {
            switch token.type {
            case .tag:
                self.tagView.add(text: token.text ?? "", config: tagTokenConfig)

            case .text:
                self.tagView.add(text: token.text ?? "", config: textTokenConfig)

            case .others:
                break
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct TagTokenConfig: MunchTagViewConfig {
        let font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        let textColor = UIColor(hex: "222222")
        let backgroundColor = UIColor.whisper100
        let extra = CGSize(width: 22, height: 13)
    }

    struct TextTokenConfig: MunchTagViewConfig {
        let font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        let textColor = UIColor(hex: "222222")
        let backgroundColor = UIColor.white
        let extra = CGSize(width: 3, height: 13)
    }
}

class SuggestCellPlace: UITableViewCell {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Suggest-Place")
        imageView.tintColor = .ba75
        return imageView
    }()

    private let nameLabel = UILabel()
            .with(font: UIFont.systemFont(ofSize: 17, weight: .medium))
            .with(color: .ba85)
            .with(numberOfLines: 1)

    private let locationLabel = UILabel(style: .small)
            .with(numberOfLines: 1)
    private let separator = SeparatorLine()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(locationLabel)
        self.addSubview(separator)

        iconView.snp.makeConstraints { maker in
            maker.left.equalTo(self).inset(24)
            maker.width.height.equalTo(24)
            maker.centerY.equalTo(self)
        }

        nameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(iconView.snp.right).inset(-16)

            maker.top.equalTo(self).inset(12)
            maker.height.equalTo(22)
        }

        locationLabel.snp.makeConstraints { maker in
            maker.left.equalTo(iconView.snp.right).inset(-16)
            maker.top.equalTo(nameLabel.snp_bottom).inset(-2)
            maker.bottom.equalTo(self).inset(12)
            maker.height.equalTo(16)
        }

        separator.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.bottom.equalTo(self)
        }
    }

    func render(place: Place) {
        nameLabel.text = place.name

        let string = NSMutableAttributedString()
        if let latLng = place.location.latLng, let distance = MunchLocation.distance(asMetric: latLng) {
            string.append(AttributedString(string: distance))
            string.append(AttributedString(string: ", "))
        }

        if let areaName = place.areas.get(0)?.name {
            string.append(AttributedString(string: areaName))
            string.append(AttributedString(string: ", "))
        }

        let locationName = place.location.neighbourhood ?? ""
        string.append(AttributedString(string: locationName))

        if place.status.type != .open {
            string.append(AttributedString(string: ", "))
            string.append(place.status.type.name.set(style: Style {
                $0.color = UIColor.primary500
            }))
        }

        locationLabel.attributedText = string
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestCellLoading: UITableViewCell {
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
}

class SuggestCellNoResult: UITableViewCell {
    private let label = UILabel()
            .with(font: UIFont.systemFont(ofSize: 17, weight: .medium))
            .with(numberOfLines: 1)
            .with(text: "No Results")

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(label)

        self.label.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestCellSuggest: UITableViewCell {
    private let label = UILabel()
            .with(font: UIFont.systemFont(ofSize: 17, weight: .regular))
            .with(numberOfLines: 0)

    var suggest: String! {
        didSet {
            let attributedText = NSMutableAttributedString()
            attributedText.append(AttributedString(string: "Did you mean "))
            attributedText.append(suggest.set(style: Style {
                $0.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            }))
            self.label.attributedText = attributedText
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(label)

        self.label.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestCellQuery: UITableViewCell {
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .ba75
        return imageView
    }()
    private let label = UILabel()
            .with(font: UIFont.systemFont(ofSize: 16, weight: .medium))
    private let separator = SeparatorLine()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(iconView)
        self.addSubview(label)
        self.addSubview(separator)

        iconView.snp.makeConstraints { maker in
            maker.left.equalTo(self).inset(24)
            maker.width.height.equalTo(24)
            maker.centerY.equalTo(self)
        }

        label.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.left.equalTo(iconView.snp.right).inset(-16)
            maker.height.equalTo(30)
            maker.top.bottom.equalTo(self).inset(12)
        }

        separator.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.bottom.equalTo(self)
        }
    }

    func render(with: (icon: String, query: SearchQuery)) {
        self.iconView.image = UIImage(named: with.icon)

        let tokens = FilterToken.getTokens(query: with.query)

        let attributed = NSMutableAttributedString()

        if let first = tokens.get(0)?.text {
            attributed.append(first.set(style: Style {
                $0.color = UIColor.black
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }))
        }
        if let second = tokens.get(1)?.text {
            attributed.append(MunchSearchTextField.period)
            attributed.append(second.set(style: Style {
                $0.color = UIColor.black
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }))
        }

        let count = tokens.count - 2
        if count > 0 {
            attributed.append(MunchSearchTextField.period)
            attributed.append("+\(count)".set(style: Style {
                $0.color = UIColor.black
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }))
        }
        label.attributedText = attributed
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
