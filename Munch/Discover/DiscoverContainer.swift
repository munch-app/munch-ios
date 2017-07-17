//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 17/7/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class DiscoverLoadingController: UIViewController {
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init Loading indicator view
        self.indicatorView.color = .primary700
        self.indicatorView.startAnimating()
    }
}

/**
 Protocol for discovery based collection controller
 */
protocol CollectionController {
    func render(collections: [CardCollection])
}

/**
 For both tab and tabless to use
 
 NOTE: 
 When working with auto layout take note of the 20px that is the top layout guide
 For container view, use the super.View.top instead
 */
protocol ExtendedDiscoverDelegate: DiscoverDelegate {
    var discoverDelegate: DiscoverDelegate! { get set }
    
    /**
     Height of the extended bar only
     */
    var extendedBarHeight: CGFloat { get }
    
    var extendedBarHeightConstraint: NSLayoutConstraint! { get }
}

extension ExtendedDiscoverDelegate {
    var searchBar: SearchNavigationBar! {
        return self.discoverDelegate.searchBar
    }
    
    func present(place: Place) {
        self.discoverDelegate.present(place: place)
    }
    
    func collectionViewDidScroll(_ scrollView: UIScrollView) {
        self.discoverDelegate.collectionViewDidScroll(scrollView)
        self.extendedBarHeightConstraint.constant = self.searchBar.height + self.extendedBarHeight
    }
    
    /**
     For tab controller, the animation is applied here and not delegated down
     */
    func collectionViewDidScrollFinish(_ scrollView: UIScrollView) {
        self.discoverDelegate.collectionViewDidScrollFinish(scrollView)
    }
    
    var headerHeight: CGFloat {
        return self.discoverDelegate.headerHeight + extendedBarHeight
    }
}

class DiscoverTabController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CollectionController, ExtendedDiscoverDelegate {
    var discoverDelegate: DiscoverDelegate!
    var collectionController: CardCollectionController!
    
    var extendedBarHeight: CGFloat = 50
    @IBOutlet weak var extendedBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabCollection: UICollectionView!
    
    var selectedTab = 0
    var collections = [CardCollection]()
    var scrollYMemory = [CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabCollection.delegate = self
        self.tabCollection.dataSource = self
    }
    
    /**
     Render collections view
     */
    func render(collections: [CardCollection]) {
        self.selectedTab = 0
        self.collections = collections
        self.scrollYMemory = collections.map { _ in return 0 }
        
        // Render those data
        self.tabCollection.reloadData()
        self.collectionController.render(collection: collections[selectedTab])
    }
    
    // MARK: - Collections
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return DiscoverTabTitleCell.width(title: collections[indexPath.row].name)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverTabTitleCell", for: indexPath) as! DiscoverTabTitleCell
        cell.render(title: collections[indexPath.row].name, selected: selectedTab == indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (self.selectedTab != indexPath.row) {
            // Save old offset
            scrollYMemory[selectedTab] = collectionController.contentOffset.y
            
            self.selectedTab = indexPath.row
            self.tabCollection.reloadData()
            
            var newY = scrollYMemory[self.selectedTab]
            if (searchBar.isFullyOpened) {
                // Bar is opened, new y will always be top
                newY = 0
            } else if (searchBar.isFullyClosed && newY == 0) {
                // Bar is closed but new y will cause it to be open, hence override
                newY = SearchNavigationBar.diffHeight
            }
            collectionController.render(collection: collections[indexPath.row], y: newY)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CardCollectionController {
            self.collectionController = controller
            controller.discoverDelegate = self
        }
    }
}

/**
 Title cell for Discovery Page
 */
class DiscoverTabTitleCell: UICollectionViewCell {
    static let titleFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIView!
    
    func render(title: String?, selected: Bool) {
        self.label.text = title == nil ? "" : title!.uppercased()
        if (selected) {
            label.textColor = UIColor.black.withAlphaComponent(0.85)
            indicator.backgroundColor = .primary300
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.35)
            indicator.backgroundColor = .white
        }
    }
    
    class func width(title: String?) -> CGSize {
        let label = title == nil ? "" : title!.uppercased()
        let width = UILabel.textWidth(font: titleFont, text: label)
        return CGSize(width: width + 20, height: 50)
    }
}

class DiscoverTablessController: UIViewController, CollectionController, ExtendedDiscoverDelegate {
    var discoverDelegate: DiscoverDelegate!
    var collectionController: CardCollectionController!
    
    var extendedBarHeight: CGFloat = 50
    @IBOutlet weak var extendedBarHeightConstraint: NSLayoutConstraint!
    
    var collection: CardCollection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     Render collections view
     */
    func render(collections: [CardCollection]) {
        self.collection = collections.get(0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CardCollectionController {
            self.collectionController = controller
            controller.discoverDelegate = self
        }
    }
}
