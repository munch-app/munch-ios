//
//  SearchCardInjected.swift
//  Munch
//
//  Created by Fuxing Loh on 20/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit

class SearchNoLocationCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.text = "No Location"
        titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(24)
        }

        descriptionLabel.text = "You have turned off your location service. Turn it on for better suggestion?"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-22)
        }

        actionButton.layer.cornerRadius = 3
        actionButton.backgroundColor = .primary
        actionButton.setTitle("Enable Location", for: .normal)
        actionButton.contentEdgeInsets.left = 32
        actionButton.contentEdgeInsets.right = 32
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
        actionButton.addTarget(self, action: #selector(enableLocation(button:)), for: .touchUpInside)
    }
    
    @objc func enableLocation(button: UIButton) {
        if MunchLocation.isEnabled {
            controller.render(searchQuery: controller.searchQuery)
        } else {
            MunchLocation.requestLocation()
            actionButton.setTitle("Refresh Search", for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
    }
    
    static var cardId: String {
        return "injected_NoLocation_20171020"
    }
}

class SearchNoResultCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)

        titleLabel.text = "No Results"
        titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(24)
        }

        descriptionLabel.text = "We couldn't find anything. Try searching something else?"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-22)
            make.bottom.equalTo(self).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
        self.controller = controller
    }

    static var cardId: String {
        return "injected_NoResult_20171208"
    }
}

class SearchNoResultAnywhereCard: UITableViewCell, SearchCardView {
    private let titleImage = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton()

    private var searchQuery: SearchQuery!
    private var controller: SearchController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(titleImage)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(actionButton)

        titleLabel.text = "No Results"
        titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.72)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(24)
        }

        descriptionLabel.text = "We couldn't find anything in that location. Try searching anywhere?"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        descriptionLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.equalTo(titleLabel.snp.bottom).inset(-22)
        }

        actionButton.layer.cornerRadius = 3
        actionButton.backgroundColor = .primary
        actionButton.setTitle("Search Anywhere", for: .normal)
        actionButton.contentEdgeInsets.left = 32
        actionButton.contentEdgeInsets.right = 32
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel!.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(descriptionLabel.snp.bottom).inset(-26)
            make.height.equalTo(48)
            make.bottom.equalTo(self).inset(24)
        }
        actionButton.addTarget(self, action: #selector(onAction(button:)), for: .touchUpInside)
    }

    @objc func onAction(button: UIButton) {
        controller.render(searchQuery: self.searchQuery)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(card: SearchCard, controller: SearchController) {
        self.searchQuery = SearchQuery(json: card["query"])
        self.controller = controller
    }

    static var cardId: String {
        return "injected_NoResultAnywhere_20171208"
    }
}