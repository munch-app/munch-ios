//
// Created by Fuxing Loh on 2018-12-07.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString

class RIPHourCard: RIPCard {
    static let openStyle = Style {
        $0.color = UIColor.open
        $0.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
    }
    static let closeStyle = Style {
        $0.color = UIColor.close
        $0.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
    }
    static let hourStyle = Style {
        $0.color = UIColor.black
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
    static let boldStyle = Style {
        $0.color = UIColor.black
        $0.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    }

    let grid = UIView()
    fileprivate let indicator: UIButton = {
        let button = UIButton()
        button.tintColor = .black
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(named: "RIP-Card-Expand"), for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()
    let openLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        label.numberOfLines = 2
        return label
    }()
    fileprivate let dayView = RIPDayView()

    var openHeightConstraint: Constraint!
    var dayHeightConstraint: Constraint!

    override func didLoad(data: PlaceData!) {
        self.addSubview(grid)
        grid.addSubview(indicator)
        grid.addSubview(openLabel)
        grid.addSubview(dayView)

        grid.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(12)
        }

        indicator.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self)
            maker.width.equalTo(20)
        }

        openLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(grid)
            maker.left.equalTo(grid)
            maker.right.equalTo(indicator.snp.left)
        }


        let hours = data.place.hours
        let grouped = hours.grouped
        dayView.render(hourGrouped: grouped)
        dayView.isHidden = true

        let attributedText = NSMutableAttributedString()
        switch grouped.isOpen() {
        case .opening:
            attributedText.append("Opening Soon\n".set(style: RIPHourCard.openStyle))
        case .open:
            attributedText.append("Open Now\n".set(style: RIPHourCard.openStyle))

        case .closing:
            attributedText.append("Closing Soon\n".set(style: RIPHourCard.closeStyle))

        case .closed: fallthrough
        case .none:
            attributedText.append("Closed Now\n".set(style: RIPHourCard.closeStyle))

        }


        attributedText.append(grouped.todayDayTimeRange.set(style: RIPHourCard.hourStyle))
        openLabel.attributedText = attributedText
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !data.place.hours.isEmpty
    }

//    override func didTap() {
//        dayView.isHidden = !dayView.isHidden
//        openLabel.isHidden = !openLabel.isHidden
//        indicator.isHidden = !indicator.isHidden
//
//        if (openLabel.isHidden) {
//            openLabel.snp.removeConstraints()
//            dayView.snp.makeConstraints { (make) in
//                make.top.bottom.equalTo(grid)
//                make.left.right.equalTo(grid)
//                make.height.equalTo(39 * 7).priority(999)
//            }
//        }
//
//        if (dayView.isHidden) {
//            dayView.snp.removeConstraints()
//            openLabel.snp.makeConstraints { (make) in
//                make.top.bottom.equalTo(grid)
//                make.left.equalTo(grid)
//                make.right.equalTo(indicator.snp.left)
//            }
//        }
//
//        self.controller.apply(click: .hours)
//    }
}

fileprivate class RIPDayView: UIView {
    let dayLabels = [UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel()]

    override init(frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.clipsToBounds = true

        for (index, label) in dayLabels.enumerated() {
            label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            label.numberOfLines = 2
            self.addSubview(label)

            label.snp.makeConstraints { make in
                make.left.right.equalTo(self)
                make.height.equalTo(42).priority(998)

                if index == 0 {
                    make.top.equalTo(self)
                } else {
                    make.top.equalTo(dayLabels[index - 1].snp.bottom)
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(hourGrouped: Hour.Grouped) {
        func createLine(day: Hour.Day, dayText: String) -> NSAttributedString {
            if day.isToday {
                switch hourGrouped.isOpen() {
                case .opening: fallthrough
                case .closing: fallthrough
                case .open:
                    return dayText.set(style: RIPHourCard.boldStyle) + "\n"
                            + hourGrouped[day].set(style: RIPHourCard.openStyle)
                case .closed: fallthrough
                case .none:
                    return dayText.set(style: RIPHourCard.boldStyle) + "\n"
                            + hourGrouped[day].set(style: RIPHourCard.closeStyle)
                }
            } else {
                return NSAttributedString(string: "\(dayText)\n\(hourGrouped[day])")
            }
        }

        dayLabels[0].attributedText = createLine(day: Hour.Day.mon, dayText: "Monday")
        dayLabels[1].attributedText = createLine(day: Hour.Day.tue, dayText: "Tuesday")
        dayLabels[2].attributedText = createLine(day: Hour.Day.wed, dayText: "Wednesday")
        dayLabels[3].attributedText = createLine(day: Hour.Day.thu, dayText: "Thursday")
        dayLabels[4].attributedText = createLine(day: Hour.Day.fri, dayText: "Friday")
        dayLabels[5].attributedText = createLine(day: Hour.Day.sat, dayText: "Saturday")
        dayLabels[6].attributedText = createLine(day: Hour.Day.sun, dayText: "Sunday")
    }
}
