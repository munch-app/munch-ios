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

    override func didLoad(data: PlaceData!) {
        self.addSubview(indicator)
        self.addSubview(openLabel)

        indicator.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self)
            maker.width.equalTo(20)
        }

        openLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(24)
            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(indicator.snp.left)
        }

        let grouped: Hour.Grouped = data.place.hours.grouped

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
        self.layoutIfNeeded()
    }

    override func didSelect(data: PlaceData!, controller: RIPController) {
        let destination = RIPHourController(place: data.place)

        let delegate = HalfModalTransitioningDelegate(viewController: controller, presentingViewController: destination)
        destination.modalPresentationStyle = .custom
        destination.transitioningDelegate = delegate
        controller.present(destination, animated: true)
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !data.place.hours.isEmpty
    }
}

fileprivate class RIPHourController: HalfModalController {
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInsetAdjustmentBehavior = .never
        view.alwaysBounceHorizontal = false
        return view
    }()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()
    private let header = UILabel(style: .h2)
            .with(numberOfLines: 0)
    private let grouped: Hour.Grouped

    init(place: Place) {
        self.grouped = place.hours.grouped
        header.with(text: "\(place.name) Hours", lineSpacing: 1.3)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(header)
        self.view.addSubview(scrollView)
        self.scrollView.addSubview(self.stackView)

        header.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeArea.top).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(header.snp.bottom).inset(-16)
            maker.bottom.equalTo(self.view.safeArea.bottom)
            maker.left.right.equalTo(self.view)
        }

        stackView.snp.makeConstraints { maker in
            maker.edges.equalTo(scrollView)
            maker.width.equalTo(scrollView.snp.width)
        }

        for attribute in getTexts(with: grouped) {
            let label = UILabel(style: .regular)
                    .with(numberOfLines: 2)
            label.attributedText = attribute

            let view = UIView()
            view.addSubview(label)
            label.snp.makeConstraints { maker in
                maker.left.right.equalTo(view).inset(24)
                maker.top.equalTo(view)
                maker.bottom.equalTo(view).inset(12)
            }
            stackView.addArrangedSubview(view)
        }
    }

    func getTexts(with grouped: Hour.Grouped) -> [NSAttributedString] {
        func createLine(day: Hour.Day, dayText: String) -> NSAttributedString {
            let line1 = dayText.set(style: Style {
                $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            })

            if day.isToday {
                switch grouped.isOpen() {
                case .opening: fallthrough
                case .closing: fallthrough
                case .open:
                    return line1 + "\n" + grouped[day].set(style: Style {
                    $0.color = UIColor.open
                })

                case .closed: fallthrough
                case .none:
                    return line1 + "\n" + grouped[day].set(style: Style {
                        $0.color = UIColor.close
                    })
                }
            } else {
                return line1 + "\n" + grouped[day]
            }
        }

        return [
            createLine(day: Hour.Day.mon, dayText: "Monday"),
            createLine(day: Hour.Day.tue, dayText: "Tuesday"),
            createLine(day: Hour.Day.wed, dayText: "Wednesday"),
            createLine(day: Hour.Day.thu, dayText: "Thursday"),
            createLine(day: Hour.Day.fri, dayText: "Friday"),
            createLine(day: Hour.Day.sat, dayText: "Saturday"),
            createLine(day: Hour.Day.sun, dayText: "Sunday")
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}