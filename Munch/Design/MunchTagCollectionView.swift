//
// Created by Fuxing Loh on 1/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

enum MunchTagCollectionType {
    case rating(Float)
    case tag(String)

    case assumptionPlus
    case assumptionTag(String)
    case assumptionText(String)
}

protocol MunchTagCollectionViewDelegate {
    func tagCollectionView(collectionView: MunchTagCollectionView, didSelect type: MunchTagCollectionType)
}

class MunchTagCollectionView: UIView {
    fileprivate var collectionView: UICollectionView!
    fileprivate var items = [MunchTagCollectionType]()

    var delegate: MunchTagCollectionViewDelegate?
    var showFullyVisibleOnly: Bool!

    required init(scrollDirection: UICollectionViewScrollDirection = .horizontal, verticalSpacing: CGFloat = 8, horizontalSpacing: CGFloat = 8, backgroundColor: UIColor = .white,
                  showFullyVisibleOnly: Bool = false) {
        super.init(frame: .zero)
        self.showFullyVisibleOnly = showFullyVisibleOnly
        self.backgroundColor = backgroundColor

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.scrollDirection = scrollDirection
        layout.minimumInteritemSpacing = verticalSpacing
        layout.minimumLineSpacing = horizontalSpacing

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(MunchTagCollectionViewCellRating.self, forCellWithReuseIdentifier: "MunchTagCollectionViewCellRating")
        collectionView.register(MunchTagCollectionViewCellTag.self, forCellWithReuseIdentifier: "MunchTagCollectionViewCellTag")
        collectionView.register(MunchTagCollectionViewCellAssumptionPlus.self, forCellWithReuseIdentifier: "MunchTagCollectionViewCellAssumptionPlus")
        collectionView.register(MunchTagCollectionViewCellAssumptionTag.self, forCellWithReuseIdentifier: "MunchTagCollectionViewCellAssumptionTag")
        collectionView.register(MunchTagCollectionViewCellAssumptionText.self, forCellWithReuseIdentifier: "MunchTagCollectionViewCellAssumptionText")
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .zero
        collectionView.backgroundColor = backgroundColor
        self.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func add(type: MunchTagCollectionType) {
        addAll(types: [type])
    }

    func addAll(types: [MunchTagCollectionType]) {
        items.append(contentsOf: types)

        UIView.setAnimationsEnabled(false)
        collectionView.reloadData()
        UIView.setAnimationsEnabled(true)
    }

    func removeAll() {
        items.removeAll()

        UIView.setAnimationsEnabled(false)
        collectionView.reloadData()
        UIView.setAnimationsEnabled(true)
    }

    func replaceAll(types: [MunchTagCollectionType]) {
        self.items = []
        addAll(types: types)
    }
}

extension MunchTagCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = items[indexPath.row]
        switch item {
        case .rating:
            return MunchTagCollectionViewCellRating.size(type: item)
        case .tag:
            return MunchTagCollectionViewCellTag.size(type: item)
        case .assumptionPlus:
            return MunchTagCollectionViewCellAssumptionPlus.size(type: item)
        case .assumptionTag:
            return MunchTagCollectionViewCellAssumptionTag.size(type: item)
        case .assumptionText:
            return MunchTagCollectionViewCellAssumptionText.size(type: item)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch items[indexPath.row] {
        case .rating:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "MunchTagCollectionViewCellRating", for: indexPath) as! MunchTagCollectionViewCellRating
        case .tag:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "MunchTagCollectionViewCellTag", for: indexPath) as! MunchTagCollectionViewCellTag
        case .assumptionPlus:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "MunchTagCollectionViewCellAssumptionPlus", for: indexPath) as! MunchTagCollectionViewCellAssumptionPlus
        case .assumptionTag:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "MunchTagCollectionViewCellAssumptionTag", for: indexPath) as! MunchTagCollectionViewCellAssumptionTag
        case .assumptionText:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "MunchTagCollectionViewCellAssumptionText", for: indexPath) as! MunchTagCollectionViewCellAssumptionText
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if showFullyVisibleOnly {
            cell.isHidden = outOfBound(view: cell, superview: collectionView)
        }

        switch items[indexPath.row] {
        case .rating(let percent):
            let cell = cell as! MunchTagCollectionViewCellRating
            cell.percent = percent
        case .tag(let text):
            let cell = cell as! MunchTagCollectionViewCellTag
            cell.textLabel.text = text

        case .assumptionPlus:
            return

        case .assumptionTag(let text):
            let cell = cell as! MunchTagCollectionViewCellAssumptionTag
            cell.textLabel.text = text
        case .assumptionText(let text):
            let cell = cell as! MunchTagCollectionViewCellAssumptionText
            cell.textLabel.text = text
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.tagCollectionView(collectionView: self, didSelect: items[indexPath.row])
    }

    private func outOfBound(view: UIView, superview: UIView) -> Bool {
        let intersectedFrame = superview.bounds.intersection(view.frame)
        let isInBounds = fabs(intersectedFrame.origin.x - view.frame.origin.x) < 1 &&
                fabs(intersectedFrame.origin.y - view.frame.origin.y) < 1 &&
                fabs(intersectedFrame.size.width - view.frame.size.width) < 1 &&
                fabs(intersectedFrame.size.height - view.frame.size.height) < 1
        return !isInBounds
    }
}

protocol MunchTagCollectionViewCellView {
    static func size(type: MunchTagCollectionType) -> CGSize
}

class MunchTagCollectionViewCellRating: UICollectionViewCell, MunchTagCollectionViewCellView {
    static let font = UIFont.systemFont(ofSize: 13.0, weight: .medium)

    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.font = font
        label.textColor = .white
        label.backgroundColor = .black
        label.textAlignment = .center
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear

        textLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var percent: Float! {
        didSet {
            let float = CGFloat(percent)
            self.textLabel.text = ReviewRatingUtils.text(percent: float)
            self.textLabel.backgroundColor = ReviewRatingUtils.color(percent: float)
        }
    }

    static func size(type: MunchTagCollectionType) -> CGSize {
        switch type {
        case .rating(let percent):
            let text = ReviewRatingUtils.text(percent: CGFloat(percent))
            return UILabel.textSize(font: font, text: text, extra: CGSize(width: 14, height: 8))
        default: return .zero
        }
    }
}

class MunchTagCollectionViewCellTag: UICollectionViewCell, MunchTagCollectionViewCellView {
    static let font = UIFont.systemFont(ofSize: 13.0, weight: .regular)

    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.font = font
        label.textColor = UIColor(hex: "222222")
        label.backgroundColor = UIColor.bgTag
        label.textAlignment = .center
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear

        textLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func size(type: MunchTagCollectionType) -> CGSize {
        switch type {
        case .tag(let text):
            return UILabel.textSize(font: font, text: text, extra: CGSize(width: 14, height: 8))
        default: return .zero
        }
    }
}

class MunchTagCollectionViewCellAssumptionPlus: UICollectionViewCell, MunchTagCollectionViewCellView {
    static let font = UIFont.systemFont(ofSize: 17.0, weight: .light)

    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.text = "＋"
        label.font = font
        label.textColor = UIColor(hex: "202020")
        label.backgroundColor = .clear
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear

        textLabel.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func size(type: MunchTagCollectionType) -> CGSize {
        return UILabel.textSize(font: font, text: "＋", extra: CGSize(width: 0, height: 8))
    }
}

class MunchTagCollectionViewCellAssumptionTag: UICollectionViewCell, MunchTagCollectionViewCellView {
    static let font = UIFont.systemFont(ofSize: 14.0, weight: .regular)

    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.font = font
        label.textColor = UIColor(hex: "303030")
        label.backgroundColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear

        textLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func size(type: MunchTagCollectionType) -> CGSize {
        switch type {
        case .assumptionTag(let text):
            return UILabel.textSize(font: font, text: text, extra: CGSize(width: 21, height: 13))
        default: return .zero
        }
    }
}

class MunchTagCollectionViewCellAssumptionText: UICollectionViewCell, MunchTagCollectionViewCellView {
    static let font = UIFont.systemFont(ofSize: 14.0, weight: .regular)

    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.font = font
        label.textColor = UIColor(hex: "303030")
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear

        textLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func size(type: MunchTagCollectionType) -> CGSize {
        switch type {
        case .assumptionText(let text):
            return UILabel.textSize(font: font, text: text, extra: CGSize(width: 2, height: 13))
        default: return .zero
        }
    }
}