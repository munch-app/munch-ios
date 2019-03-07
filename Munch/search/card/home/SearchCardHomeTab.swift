//
// Created by Fuxing Loh on 2018-11-30.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

fileprivate enum HomeTab {
    case Between
    case Search
    case Location

    var text: String {
        switch self {
        case .Between: return "EatBetween"
        case .Search: return "Search"
        case .Location: return "Neighbourhoods"
        }
    }

    var image: String {
        switch self {
        case .Between: return "Search-Card-Home-Tab-Between"
        case .Search: return "Search-Card-Home-Tab-Search"
        case .Location: return "Search-Card-Home-Tab-Location"
        }
    }

    var leftIcon: UIImage? {
        switch self {
        case .Between: return UIImage(named: "Search-Filter-Location-EatBetween")
        default: return UIImage(named: "Search-Header-Glass")
        }
    }

    var hint: String {
        switch self {
        case .Between: return "Try EatBetween"
        case .Search: return "Search e.g. Italian in Orchard"
        case .Location: return "Search Location"
        }
    }

    var rightIcon: UIImage? {
        switch self {
        case .Search: return UIImage(named: "Search-Header-Filter")
        default: return nil
        }
    }

    var message: String {
        switch self {
        case .Between: return "Enter everyone’s location and we’ll find the most ideal spot for a meal together."
        case .Search: return "Search anything on Munch and we’ll give you the best recommendations."
        case .Location: return "Enter a location and we’ll tell you what’s delicious around."
        }
    }
}

class SearchHomeTabCard: SearchCardView {
    let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)

    static let createText = "(Not Samantha? Create an account here.)"
    let createBtn: UIControl = {
        let label = UILabel(style: .h6)
                .with(text: createText)

        let button = UIControl()
        button.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.edges.equalTo(button)
        }
        return button
    }()

    var loggedInConstraints: Constraint!

    override func didLoad(card: SearchCard) {
        self.addSubview(titleLabel)
        self.addSubview(createBtn)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
            loggedInConstraints = maker.bottom.equalTo(self).inset(topBottom).constraint
        }

        createBtn.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
            maker.bottom.equalTo(self).inset(topBottom).priority(.low)
        }

        self.createBtn.addTarget(self, action: #selector(onCreateAccount), for: .touchUpInside)
    }

    override func willDisplay(card: SearchCard) {
        self.titleLabel.text = SearchHomeTabCard.title

        if Authentication.isAuthenticated() {
            createBtn.isHidden = true
            loggedInConstraints.activate()
        } else {
            createBtn.isHidden = false
            loggedInConstraints.deactivate()
        }
    }

    override class func height(card: SearchCard) -> CGFloat {
        let title = FontStyle.h2.height(text: SearchHomeTabCard.title, width: self.contentWidth)
        let min = topBottom + title + topBottom

        if Authentication.isAuthenticated() {
            return min
        }

        let create = FontStyle.h6.height(text: createText, width: self.contentWidth)
        return min + 4
    }

    override class var cardId: String {
        return "HomeTab_2018-11-29"
    }
}

extension SearchHomeTabCard {
    @objc func onCreateAccount() {
        Authentication.requireAuthentication(controller: self.controller) { state in
            guard case .loggedIn = state else {
                return
            }

            self.controller.reset()
        }
    }
}

extension SearchHomeTabCard {
    class var title: String {
        return "\(salutation), \(name). Feeling hungry?"
    }

    class var salutation: String {
        let date = Date()
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)

        let total = (hour * 60) + minute
        if total >= 300 && total < 720 {
            return "Good Morning"
        } else if total >= 720 && total < 1020 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    class var name: String {
        if !Authentication.isAuthenticated() {
            return "Samantha"
        }
        return UserProfile.instance?.name ?? "Samantha"
    }
}
