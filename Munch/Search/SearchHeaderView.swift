//
//  SearchHeaderView.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import TTGTagCollectionView

/**
 SearchHeader controls data managements query, update refresh
 SearchController only controls rendering of the data
 */
class SearchHeaderView: UIView, SearchFilterTagDelegate {
    let controller: UIViewController

    let textButton = SearchTextButton()
    let tagCollection = SearchFilterTagCollection()

    var heightConstraint: Constraint! = nil

    var searchQuery = SearchQuery()

    init(controller: UIViewController) {
        self.controller = controller
        super.init(frame: CGRect())
        self.tagCollection.delegate = self
        self.initViews()
    }

    private func initViews() {
        self.backgroundColor = UIColor.white
        let statusView = UIView()

        self.addSubview(tagCollection)
        self.addSubview(textButton)
        self.addSubview(statusView)

        statusView.backgroundColor = UIColor.white
        statusView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(20)
        }

        textButton.addTarget(self, action: #selector(onHeaderAction(for:)), for: .touchUpInside)
        textButton.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.height.equalTo(52)
            make.top.equalTo(statusView.snp.bottom)
        }

        tagCollection.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(24)
            make.bottom.equalTo(self).inset(8)
        }

        self.snp.makeConstraints { make in
            self.heightConstraint = make.height.equalTo(maxHeight).constraint
        }
    }

    @objc func onHeaderAction(for view: UIView) {
        if view is SearchTextButton {
            controller.performSegue(withIdentifier: "SearchHeaderView_suggest", sender: self)
        }
    }

    func tagCollection(selectedLocation tagCollection: SearchFilterTagCollection) {
        controller.performSegue(withIdentifier: "SearchHeaderView_location", sender: self)
    }

    func tagCollection(selectedPlus tagCollection: SearchFilterTagCollection) {
        controller.performSegue(withIdentifier: "SearchHeaderView_filter", sender: self)
    }

    func tagCollection(selectedTag tagCollection: SearchFilterTagCollection, didTapTag tagText: String!) {
        controller.performSegue(withIdentifier: "SearchHeaderView_filter", sender: self)
    }

    func render(query: SearchQuery) {
        // TODO Search Navigation Tracking
        // Added to list if added
        self.textButton.render(query: query)
        self.tagCollection.render(query: query)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.hairlineShadow(height: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchTextButton: UIButton {
    private let field = SearchTextField()

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white

        field.layer.cornerRadius = 4
        field.color = UIColor(hex: "2E2E2E")
        field.backgroundColor = UIColor.init(hex: "EBEBEB")

        field.leftImage = UIImage(named: "SC-Search-18")
        field.leftImagePadding = 3
        field.leftImageWidth = 32
        field.leftImageSize = 18

        field.placeholder = "Search Anything"
        field.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)

        field.isEnabled = false

        self.addSubview(field)
        field.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.bottom.equalTo(self).inset(8)
        }
    }

    func render(query: SearchQuery) {
        self.field.text = query.query
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchFilterButton: UIButton {
    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)

        self.setImage(UIImage(named: "icons8-Horizontal Settings Mixer-30"), for: .normal)
        self.tintColor = UIColor.black
        self.contentHorizontalAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchFilterTagCollection: UIView, TTGTextTagCollectionViewDelegate {
    let tagCollection = TTGTextTagCollectionView()
    let defaultTagConfig = DefaultTagConfig()
    let plusTagConfig = DefaultTagConfig()

    var delegate: SearchFilterTagDelegate?

    override init(frame: CGRect = CGRect()) {
        super.init(frame: frame)
        self.addSubview(tagCollection)
        plusTagConfig.tagTextFont = UIFont.systemFont(ofSize: 17.0, weight: .light)
        plusTagConfig.tagExtraSpace = CGSize(width: 13, height: 8)

        tagCollection.delegate = self
        tagCollection.defaultConfig = defaultTagConfig
        tagCollection.horizontalSpacing = 10
        tagCollection.contentInset = UIEdgeInsets.init(topBottom: 2, leftRight: 0)

        tagCollection.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    func render(query: SearchQuery) {
        var tags = [String]()

        // FirstTag: Location Tag
        if let locationName = query.location?.name {
            tags.append(locationName)
        } else if MunchLocation.isEnabled {
            tags.append("Nearby")
        } else {
            tags.append("Singapore")
        }

        // Other Tags
        for tag in query.filter.tag.positives {
            tags.append(tag)
        }

        render(tags: tags)
    }

    private func render(tags: [String]) {
        tagCollection.removeAllTags()
        tagCollection.addTags(tags)
        tagCollection.addTag("＋", with: plusTagConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class DefaultTagConfig: TTGTextTagConfig {
        override init() {
            super.init()

            tagTextFont = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            tagShadowOffset = CGSize.zero
            tagShadowRadius = 0

            tagBorderWidth = 0.5
            tagBorderColor = UIColor.black.withAlphaComponent(0.25)
            tagTextColor = UIColor.black.withAlphaComponent(0.75)
            tagBackgroundColor = UIColor.white

            tagSelectedBorderWidth = 0.5
            tagSelectedBorderColor = UIColor.black.withAlphaComponent(0.25)
            tagSelectedTextColor = UIColor.black.withAlphaComponent(0.75)
            tagSelectedBackgroundColor = UIColor.white

            tagExtraSpace = CGSize(width: 21, height: 13)
        }
    }

    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        if (index == 0) {
            // Location Selected
            delegate?.tagCollection(selectedLocation: self)
        } else if (tagText.hasPrefix("＋")) {
            // Is ＋ button selected
            delegate?.tagCollection(selectedPlus: self)
        } else {
            // Filter selected
            delegate?.tagCollection(selectedTag: self, didTapTag: tagText)
        }
    }
}

/**
 Delegate tool for SearchFilterTag
 */
protocol SearchFilterTagDelegate {
    func tagCollection(selectedLocation tagCollection: SearchFilterTagCollection)

    func tagCollection(selectedPlus tagCollection: SearchFilterTagCollection)

    func tagCollection(selectedTag tagCollection: SearchFilterTagCollection, didTapTag tagText: String!)
}

class HeaderViewSegue: UIStoryboardSegue {
    override func perform() {
        super.perform()
        let searchQuery = (source as! SearchController).searchQuery

        if let navigation = destination as? UINavigationController {
            let controller = navigation.topViewController
            if let query = controller as? SearchQueryController {
                query.searchQuery = searchQuery
            } else if let filter = controller as? SearchFilterController {
                filter.searchQuery = searchQuery
            } else if let location = controller as? SearchLocationController {
                location.searchQuery = searchQuery
            }
        }
    }
}

// Header Scroll to Hide Functions
extension SearchHeaderView {
    var maxHeight: CGFloat {
        return 114
    }
    var minHeight: CGFloat {
        return 75
    }
    var centerHeight: CGFloat {
        return minHeight + 23
    }

    func contentDidScroll(scrollView: UIScrollView) {
        let height = calculateHeight(scrollView: scrollView)
        self.heightConstraint.layoutConstraints[0].constant = height
    }

    /**
     nil means don't move
     */
    func contentShouldMove(scrollView: UIScrollView) -> CGFloat? {
        let height = calculateHeight(scrollView: scrollView)

        // Already fully closed or opened
        if (height == maxHeight || height == minHeight) {
            return nil
        }

        if (height < centerHeight) {
            // To close
            return -minHeight
        } else {
            // To open
            return -maxHeight
        }
    }

    private func calculateHeight(scrollView: UIScrollView) -> CGFloat {
        let y = scrollView.contentOffset.y
        if y <= -maxHeight {
            return maxHeight
        } else if y >= -minHeight {
            return minHeight
        } else {
            return Swift.abs(y)
        }
    }
}

/**
 Designable search field for Discovery page
 */
@IBDesignable class SearchTextField: UITextField {

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftImagePadding
        textRect.size.width = leftImageWidth
        return textRect
    }

    @IBInspectable var leftImagePadding: CGFloat = 0
    @IBInspectable var leftImageWidth: CGFloat = 20
    @IBInspectable var leftImageSize: CGFloat = 18 {
        didSet {
            updateView()
        }
    }


    @IBInspectable var leftImage: UIImage? {
        didSet {
            updateView()
        }
    }

    @IBInspectable var color: UIColor = UIColor.lightGray {
        didSet {
            updateView()
        }
    }

    func updateView() {
        if let image = leftImage {
            leftViewMode = UITextFieldViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
            imageView.contentMode = .scaleAspectFit

            imageView.image = image
            imageView.tintColor = color
            leftView = imageView
        } else {
            leftViewMode = UITextFieldViewMode.never
            leftView = nil
        }

        // Placeholder text color
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ? placeholder! : "", attributes: [NSAttributedStringKey.foregroundColor: color])
    }
}