//
// Created by Fuxing Loh on 2018-12-14.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString

class FeedImageHeaderView: UIView {
    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

    let titleView: UILabel = {
        let titleView = UILabel(style: .navHeader)
        return titleView
    }()
    let backgroundView = UIView()
    let shadowView = UIView()

    override var isOpaque: Bool {
        didSet {
            if isOpaque {
                self.backButton.tintColor = .black
                self.titleView.textColor = .black
                self.backgroundView.backgroundColor = .white
                self.shadowView.isHidden = false
            } else {
                self.titleView.textColor = .white
                self.backButton.tintColor = .white
                self.backgroundView.backgroundColor = .clear
                self.shadowView.isHidden = true
            }
        }
    }

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)
        self.addSubview(titleView)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.bottom.equalTo(self)

            make.width.equalTo(52)
            make.height.equalTo(44)
        }

        titleView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self.backButton)
            maker.left.equalTo(backButton.snp.right)
            maker.right.equalTo(self).inset(24)
        }

        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        self.isOpaque = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedImageFooterView: UIView {
    let addButton = AddPlaceButton()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(addButton)

        addButton.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(10)
            maker.bottom.equalTo(self.safeArea.bottom).inset(10)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedImageViewImage: UIView {
    let imageView: SizeImageView = {
        let imageView = SizeImageView(points: UIScreen.main.bounds.width, height: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    init(item: FeedItem) {
        super.init(frame: .zero)
        self.addSubview(imageView)


        imageView.render(image: item.image)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self).priority(999)
            if let size = item.image?.sizes.max {
                maker.height.equalTo(imageView.snp.width).multipliedBy(size.heightMultiplier)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedImageViewContent: UIControl {
    let topLine = SeparatorLine()
    let botLine = SeparatorLine()
    let caption = UILabel(style: .subtext)
            .with(numberOfLines: 2)
    let username = UILabel(style: .h5)
            .with(numberOfLines: 1)

    init(item: FeedItem) {
        super.init(frame: .zero)
        self.addSubview(topLine)
        self.addSubview(botLine)
        self.addSubview(caption)
        self.addSubview(username)

        caption.text = item.instagram?.caption

        let mutable = NSMutableAttributedString()
        mutable.append(NSAttributedString(string: "by "))
        mutable.append((item.instagram?.username ?? "").set(style: Style {
            $0.color = UIColor.secondary700
        }))
        mutable.append(NSAttributedString(string: " on \(item.createdMillis.asMonthDayYear)"))
        username.attributedText = mutable

        topLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self)
        }

        caption.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(topLine.snp.bottom).inset(-24)
        }

        username.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(caption.snp.bottom).inset(-8)
            maker.bottom.equalTo(botLine.snp.top).inset(-24)
        }

        botLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedImageViewPlace: UIControl {
    let label = UILabel(style: .h2)
            .with(text: "Place Mentioned")
    let card = PlaceCard()

    init(place: Place, controller: UIViewController) {
        super.init(frame: .zero)
        self.addSubview(label)
        self.addSubview(card)

        card.isUserInteractionEnabled = false
        card.place = place

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(8)
            maker.height.equalTo(32)
        }

        card.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(120)
            maker.top.equalTo(label.snp.bottom).inset(-24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}