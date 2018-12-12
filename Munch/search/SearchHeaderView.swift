//
// Created by Fuxing Loh on 20/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView {
    static let height: CGFloat = 64

    let backButton = SearchBackButton()
    let textButton = SearchTextButton()
    let filterButton = SearchFilterButton()

    var controller: SearchController!
    var searchQuery: SearchQuery! {
        didSet {
            if self.controller.histories.count > 1 {
                self.textButton.field.set(icon: .back)
                self.textButton.field.set(searchQuery: self.searchQuery)
                self.backButton.isHidden = false
            } else {
                self.textButton.field.placeholder = "Try \"Chinese\""
                self.textButton.field.set(icon: .glass)
                self.backButton.isHidden = true
            }
        }
    }

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.addSubview(textButton)
        self.addSubview(backButton)
        self.addSubview(filterButton)

        self.addTargets()

        textButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.height.equalTo(SearchHeaderView.height)
            make.bottom.equalTo(self)

            make.left.equalTo(self).inset(24)
            make.right.equalTo(filterButton.snp.left)
        }

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)

            make.left.equalTo(self)
            make.width.equalTo(24 + 40)
        }

        filterButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.bottom.equalTo(self)

            make.width.equalTo(48 + 24)
            make.right.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: 3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchHeaderView {
    func addTargets() {
        filterButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
    }

    @objc func onHeaderAction(for view: UIView) {
        if view is SearchTextButton {
            self.controller.present(SuggestRootController(searchQuery: searchQuery) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }, animated: true)
        } else if view is SearchBackButton {
            self.controller.pop()
        } else if view is SearchFilterButton {
            self.controller.present(FilterRootController(searchQuery: searchQuery) { query in
                if let query = query {
                    self.controller.push(searchQuery: query)
                }
            }, animated: true)
        }
    }
}

// MARK: Buttons
class SearchBackButton: UIButton {

}

class SearchFilterButton: UIButton {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        setImage(UIImage(named: "Search-Header-Filter"), for: .normal)
        tintColor = .ba85
        contentHorizontalAlignment = .right
        contentEdgeInsets.right = 24
        backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchTextButton: UIButton {
    fileprivate let field = MunchSearchTextField()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(field)
        self.backgroundColor = .white

        field.isEnabled = false
        field.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}