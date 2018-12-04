//
// Created by Fuxing Loh on 2018-12-02.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Localize_Swift

class FilterHeaderView: UIView {
    let tagView = FilterHeaderTagView()
    let resetButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Search-Header-Reset"), for: .normal)
        button.tintColor = .black
        return button
    }()
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Search-Header-Close"), for: .normal)
        button.tintColor = .black
        button.imageEdgeInsets.right = 24
        button.contentHorizontalAlignment = .right
        return button
    }()

    var manager: FilterManager!
    var searchQuery: SearchQuery? {
        didSet {
            self.tagView.query = self.searchQuery
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self.addSubview(tagView)
        self.addSubview(resetButton)
        self.addSubview(closeButton)

        tagView.snp.makeConstraints { maker in
            maker.top.equalTo(self.safeArea.top).inset(10)
            maker.bottom.equalTo(self).inset(10)
            maker.height.equalTo(32)

            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(resetButton.snp.right).inset(-16)
        }

        resetButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(tagView)
            maker.right.equalTo(closeButton.snp.left).inset(-8)
            maker.width.equalTo(24)
        }

        closeButton.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(tagView)

            maker.right.equalTo(self)
            maker.width.equalTo(24 + 24)
        }
    }

    var tags: [FilterToken] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FilterHeaderTagView: UIView {
    var first = TagView()
    var second = TagView()
    var third = TagView()

    var tags = [FilterToken]()
    var query: SearchQuery? {
        didSet {
            if let query = self.query {
                let tags = FilterToken.getTokens(query: query)
                self.first.text = tags.get(0)?.text
                self.second.text = tags.get(1)?.text

                let count = tags.count - 2
                self.third.text = count > 0 ? "+\(count)" : nil
            } else {
                self.first.text = nil
                self.second.text = nil
                self.third.text = nil
            }
        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(first)
        self.addSubview(second)
        self.addSubview(third)

        first.snp.makeConstraints { maker in
            maker.left.equalTo(self)
            maker.top.bottom.equalTo(self)
        }

        second.snp.makeConstraints { maker in
            maker.left.equalTo(first.snp_right).inset(-10)
            maker.top.bottom.equalTo(self)
        }

        third.snp.makeConstraints { maker in
            maker.left.equalTo(second.snp_right).inset(-10)
            maker.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class TagView: UIButton {
        private let textLabel = UILabel()
                .with(size: 14, weight: .medium, color: .ba80)

        var text: String? {
            set(value) {
                if let value = value {
                    self.isHidden = false
                    self.textLabel.text = value
                } else {
                    self.isHidden = true
                }
            }
            get {
                return self.textLabel.text
            }
        }

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(textLabel)

            self.backgroundColor = .whisper100
            self.layer.cornerRadius = 4

            self.textLabel.snp.makeConstraints { maker in
                maker.left.right.equalTo(self).inset(11)
                maker.top.bottom.equalTo(self)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}