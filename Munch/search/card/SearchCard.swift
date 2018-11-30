//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

protocol SearchCardView {
    func render(card: SearchCard, delegate: SearchTableViewDelegate)

    // The these CGFloat methods are used to help SearchCard calculate it's height & width

    var leftRight: CGFloat { get }
    var topBottom: CGFloat { get }

    static var leftRight: CGFloat { get }
    static var topBottom: CGFloat { get }

    static var width: CGFloat { get }
    static var contentWidth: CGFloat { get }

    static func height(card: SearchCard) -> CGFloat

    static var cardId: String { get }
}

extension SearchCardView {
    var leftRight: CGFloat {
        return 24.0
    }

    var topBottom: CGFloat {
        return 18.0
    }

    static var leftRight: CGFloat {
        return 24.0
    }

    static var topBottom: CGFloat {
        return 18.0
    }

    static var width: CGFloat {
        return UIScreen.main.bounds.width
    }

    static var contentWidth: CGFloat {
        return width - (leftRight * 2)
    }

    // Default: Autosizing
    static func height(card: SearchCard) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    /**
     * Helper method to create SearchCard from SearchCardView
     */
    static var card: SearchCard {
        return SearchCard(cardId: cardId)
    }
}

