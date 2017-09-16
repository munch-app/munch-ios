//
//  SearchHeaderView.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

//protocol SearchHeaderDelegate {
//    func searchHeaderAction()
//}
//
//
//class SearchHeaderView: UIView {
//    // Collection tab view can be placed here
//    var extensionView: UIView?
//    
//    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
//    
//    static let maxHeight: CGFloat = 103.0
//    static let minHeight: CGFloat = 20.0
//    static let diffHeight: CGFloat = 83.0
//    
//    var searchQuery = SearchQuery()
//    
//    @IBAction func actionTouchUp(_ sender: Any) {
//        // TODO check action and delegate down
//    }
//}
//
//// Height operations for navigation bar
//extension SearchHeaderView {
//    var height: CGFloat {
//        return heightConstraint.constant
//    }
//    
//    /**
//     Distance from nearest open or close
//     */
//    var diffFromNearestY: CGFloat {
//        let currentHeight = height
//        if (currentHeight < (SearchNavigationBar.diffHeight / 2) + SearchNavigationBar.minHeight) {
//            return currentHeight - SearchNavigationBar.minHeight
//        } else {
//            return currentHeight - SearchNavigationBar.maxHeight
//        }
//    }
//    
//    /**
//     Check if the bar is fully closed
//     */
//    var isFullyClosed: Bool {
//        return height == SearchNavigationBar.minHeight
//    }
//    
//    /**
//     Check if the bar is fully opened
//     */
//    var isFullyOpened: Bool {
//        return height == SearchNavigationBar.maxHeight
//    }
//    
//    /**
//     Calculate height that the search bar should be based on the
//     Scroll position of relative y
//     */
//    func calculateHeight(relativeY: CGFloat) -> CGFloat {
//        if (relativeY >= SearchNavigationBar.diffHeight) {
//            return SearchNavigationBar.minHeight
//        } else if (relativeY <= 0) {
//            return SearchNavigationBar.maxHeight
//        } else {
//            return SearchNavigationBar.minHeight + SearchNavigationBar.diffHeight - relativeY
//        }
//    }
//    
//    /**
//     Update height progress of naivgation bar live
//     Update with current y progress
//     */
//    func updateHeight(relativeY: CGFloat) {
//        // Calculate progress for navigation bar
//        let currentHeight = heightConstraint.constant
//        let shouldHeight = calculateHeight(relativeY: relativeY)
//        
//        // Update constant if not the same, height and top constraint
//        if (currentHeight != shouldHeight) {
//            heightConstraint.constant = shouldHeight
//            
//            // Progress, 100% bar fully extended
//            var progress = (shouldHeight - SearchNavigationBar.minHeight) / SearchNavigationBar.diffHeight
//            progress = progress < 0.2 ? 0 : (progress - 0.3) * 2
//            locationButton.alpha = progress
//            searchField.alpha = progress
//            actionButton.alpha = progress
//        }
//    }
//}
//
//// Apply and Reset functions for navigation bar
//extension SearchHeaderView {
//    // TODO
//}
//
///**
// Designable search field for Discovery page
// */
//@IBDesignable class SearchTextField: UITextField {
//    
//    // Provides left padding for images
//    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
//        var textRect = super.leftViewRect(forBounds: bounds)
//        textRect.origin.x += leftImagePadding
//        textRect.size.width = leftImageWidth
//        return textRect
//    }
//    
//    @IBInspectable var leftImagePadding: CGFloat = 0
//    @IBInspectable var leftImageWidth: CGFloat = 20
//    @IBInspectable var leftImageSize: CGFloat = 18 {
//        didSet {
//            updateView()
//        }
//    }
//    
//    
//    @IBInspectable var leftImage: UIImage? {
//        didSet {
//            updateView()
//        }
//    }
//    
//    @IBInspectable var color: UIColor = UIColor.lightGray {
//        didSet {
//            updateView()
//        }
//    }
//    
//    func updateView() {
//        if let image = leftImage {
//            leftViewMode = UITextFieldViewMode.always
//            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageSize, height: leftImageSize))
//            imageView.contentMode = .scaleAspectFit
//            
//            imageView.image = image
//            imageView.tintColor = color
//            leftView = imageView
//        } else {
//            leftViewMode = UITextFieldViewMode.never
//            leftView = nil
//        }
//        
//        // Placeholder text color
//        attributedPlaceholder = NSAttributedString(string: placeholder != nil ?  placeholder! : "", attributes:[NSForegroundColorAttributeName: color])
//    }
//}
