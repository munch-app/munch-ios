//
// Created by Fuxing Loh on 2019-02-14.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import NVActivityIndicatorView

enum LocationIcon {
    case recent
    case saved
    case home
    case work
    case current

    var named: String {
        switch self {
        case .recent:
            return "Location_Recent"
        case .saved:
            return "Location_Bookmark_Filled"
        case .home:
            return "Location_Home"
        case .work:
            return "Location_Work"
        case .current:
            return "Location_Nearby"
        }
    }
}

class SearchLocationIconTextCell: UITableViewCell {
    private let leftIcon = UIImageView()
    private let label = UILabel(style: .regular)
            .with(numberOfLines: 1)

    private let rightIcon = IconView(size: 24)
    private let rightView: PaddingWidget
    private var rightPressed: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        self.rightView = PaddingWidget(
                h: 24, v: 12, view: rightIcon
        )
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(leftIcon)
        self.addSubview(label)
        self.addSubview(rightView)

        leftIcon.tintColor = .black
        leftIcon.snp.makeConstraints { maker in
            maker.width.height.equalTo(24)
            maker.left.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(12)
        }

        label.snp.makeConstraints { maker in
            maker.left.equalTo(leftIcon.snp.right).inset(-16)
            maker.top.bottom.equalTo(self)

            maker.right.equalTo(self).priority(.high)
            maker.right.equalTo(rightView.snp.left)
        }

        rightView.snp.makeConstraints { maker in
            maker.right.top.bottom.equalTo(self)
        }

        self.rightView.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onRightPressed)))
    }

    @discardableResult
    func render(with item: (text: String, icon: LocationIcon)) -> SearchLocationIconTextCell {
        label.text = item.text
        leftIcon.image = UIImage(named: item.icon.named)
        return self
    }

    @discardableResult
    func render(right icon: UIImage?, rightPressed: (() -> ())? = nil) -> SearchLocationIconTextCell {
        if let icon = icon {
            rightIcon.image = icon
            rightView.view.isHidden = false
            self.rightPressed = rightPressed
        } else {
            rightView.view.isHidden = true
            self.rightPressed = nil
        }
        return self
    }

    @objc func onRightPressed() {
        self.rightPressed?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchLocationHeaderCell: UITableViewCell {
    private let label = UILabel(style: .h4)
            .with(numberOfLines: 1)

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
            maker.bottom.equalTo(self).inset(8)
        }
    }

    @discardableResult
    func render(with text: String) -> SearchLocationHeaderCell {
        label.text = text
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchLocationTextCell: UITableViewCell {
    private let label = UILabel(style: .regular)
            .with(numberOfLines: 1)

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(12)
        }
    }

    @discardableResult
    func render(with text: String) -> SearchLocationTextCell {
        label.text = text
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchLocationLoadingCell: UITableViewCell {
    private var indicator: NVActivityIndicatorView!

    override required init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .secondary500, padding: 0)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self).inset(12)
            make.height.equalTo(36)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}