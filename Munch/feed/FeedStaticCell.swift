//
// Created by Fuxing Loh on 2018-12-03.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import NVActivityIndicatorView

class FeedCellHeader: UICollectionViewCell {
    static let text = "Add places to your Tastebud to savour them later."
    private let title = UILabel(style: .h1)
            .with(text: "Feed")

    private let subtitle = UILabel(style: .regular)
            .with(text: text)
            .with(numberOfLines: 0)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(title)
        self.addSubview(subtitle)

        title.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self)
            maker.height.equalTo(32).priority(.high)
        }

        subtitle.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(title.snp.bottom).inset(-12)

            let height = FontStyle.regular.height(text: FeedCellHeader.text, width: UIScreen.main.bounds.width - 48)
            maker.height.equalTo(height).priority(.high)
            maker.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedCellLoading: UICollectionViewCell {
    fileprivate let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .secondary500, padding: 0)
        indicator.stopAnimating()
        return indicator
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(indicator)

        indicator.startAnimating()
        indicator.snp.makeConstraints { maker in
            maker.height.equalTo(36).priority(.high)
            maker.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}