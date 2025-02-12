//
// Created by Fuxing Loh on 18/3/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

class MunchTagView: UIView {
    private static let defaultConfig = DefaultTagViewConfig()

    private let cells: [MunchTagViewCellTag]
    private var index = 0

    private var spacing: CGFloat
    private var extends: Bool

    var isEmpty: Bool {
        return cells.isEmpty || cells[0].isHidden
    }

    init(count: Int = 6, spacing: CGFloat = 8, extends: Bool = false) {
        self.spacing = spacing
        self.extends = extends

        var cells = [MunchTagViewCellTag]()
        for _ in 1...count {
            cells.append(MunchTagViewCellTag())
        }
        self.cells = cells
        super.init(frame: .zero)

        for cell in cells {
            cell.isHidden = true
            self.addSubview(cell)
        }
    }

    func add(text: String, config: MunchTagViewConfig = defaultConfig) {
        if index < cells.count {
            let cell = cells[index]
            cell.render(text: text, config: config)
            cell.isHidden = false

            if let previous = cells.get(index - 1) {
                let x = previous.frame.origin.x + spacing + previous.frame.size.width
                cell.frame.origin.x = x
            }
        }
        self.index += 1
    }

    func removeAll() {
        for cell in cells {
            cell.isHidden = true
        }
        self.index = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Only check if rendering have space if extends is disabled
        if !extends {
            var previousX: CGFloat = 0
            for (n, cell) in cells.enumerated() {
                guard n < self.index else {
                    return
                }

                previousX += cell.frame.size.width
                cell.isHidden = !(previousX <= self.frame.width)
                previousX += spacing
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MunchTagViewCellTag: UIView {
    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.borderWidth = 0
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear
    }

    func render(text: String, config: MunchTagViewConfig) {
        self.textLabel.text = text

        self.textLabel.font = config.font
        self.textLabel.textColor = config.textColor
        self.textLabel.backgroundColor = config.backgroundColor

        var size = config.size(text: text)
        size.width = ceil(size.width)
        size.height = ceil(size.height)

        self.textLabel.frame.size = size
        self.frame.size = size
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MunchTagViewConfig {
    var font: UIFont { get }
    var textColor: UIColor { get }
    var backgroundColor: UIColor { get }

    var extra: CGSize { get }
}

extension MunchTagViewConfig {
    func size(text: String) -> CGSize {
        return UILabel.textSize(font: font, text: text, extra: extra)
    }
}

struct DefaultTagViewConfig: MunchTagViewConfig {
    let font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
    let textColor = UIColor(hex: "222222")
    let backgroundColor = UIColor.whisper100

    let extra = CGSize(width: 14, height: 8)
}

struct PriceTagViewConfig: MunchTagViewConfig {
    let font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
    let textColor = UIColor(hex: "222222")
    let backgroundColor = UIColor.peach100

    let extra = CGSize(width: 10, height: 8)
}
