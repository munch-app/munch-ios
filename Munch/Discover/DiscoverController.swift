//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 21/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MXPagerView
import SafariServices

class DiscoverViewController: UIViewController, MXPagerViewDelegate, MXPagerViewDataSource, MXPageSegueSource, DiscoverViewDelegate {
   
    var pageIndex: Int = 0
    // 0 = LinearCollection, 1 = Filter
    var pageControllers = [Int: UIViewController]()
    @IBOutlet weak var pagerView: MXPagerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .tab
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Temporary render for testing
        let controller = pageControllers[0] as! DiscoverLinearCollectionController
        controller.render(collections: [
            PlaceCollection(name: "NEARBY", query: SearchQuery(), places: [Place(), Place(), Place()]),
            PlaceCollection(name: "HEALTHY OPTIONS", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "CAFES", query: SearchQuery(), places: [Place(), Place()]),
            PlaceCollection(name: "PUBS & BARS", query: SearchQuery(), places: [Place(), Place()])
        ])
    }
    
    // MARK: - Pager view delegate
    func pagerView(_ pagerView: MXPagerView, didMoveToPage page: UIView, at index: Int) {
    }
    
    // MARK: - Pager segue source
    func setPageViewController(_ pageViewController: UIViewController, at index: Int) {
        pageControllers[index] = pageViewController
        if (index == 0) {
            (pageControllers[0] as! DiscoverLinearCollectionController).rootDelegate = self
        }
    }
    
    // MARK: - Pager view data source
    func numberOfPages(in pagerView: MXPagerView) -> Int {
        return 2
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        if let page = pageControllers[index] {
            return page.view
        }
        
        // If don't exist, perform it first
        let identifier = "mx_page_\(index)"
        self.pageIndex = index
        self.performSegue(withIdentifier: identifier, sender: nil)
        return pageControllers[index]?.view
    }
   
    /**
     Main content view scrolling
     */
    func contentViewDidScroll(scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        print(position)
    }
    
    /**
     Unwind to main Discover View Controller
     */
    @IBAction func unwindToDiscover(segue: UIStoryboardSegue) {
        
    }
    
    /**
     Wind to place discover view controller
     */
    func present(place: Place) {
//        let storyboard = UIStoryboard(name: "Place", bundle: nil)
//        let controller = storyboard.instantiateInitialViewController()!
    }
}

protocol DiscoverViewDelegate {
    /**
     Present place controller with place data
     */
    func present(place: Place)
    
    /**
     Did scroll content view
     */
    func contentViewDidScroll(scrollView: UIScrollView)
}


class DiscoverLinearCollectionController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MXPagerViewDelegate, MXPagerViewDataSource {
    
    var rootDelegate: DiscoverViewDelegate!
    let titleFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleCollection: UICollectionView!
    @IBOutlet weak var pagerView: MXPagerView!
    
    
    var collectionViews = [DiscoverCollectionView]()
    var collections = [PlaceCollection]()
    var selectedPage = 0
    
    /**
     Setup hairline for title view
     Setup delegate and data source for pager and title collection
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        titleView.hairlineShadow()
        titleCollection.delegate = self
        titleCollection.dataSource = self
        titleCollection.showsHorizontalScrollIndicator = false
        
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.transitionStyle = .tab
    }
    
    /**
     Dynamically load new collection view if need to
     */
    func render(collections: [PlaceCollection]) {
        self.collections = collections
        
        // Check if have enough collection views, if not add more
        let need = collections.count - collectionViews.count
        if (need != 0) {
            for _ in 1...need {
                let collectonView = DiscoverCollectionView()
                collectonView.rootDelegate = rootDelegate
                collectionViews.append(collectonView)
            }
        }
        
        // Reload title and pager
        self.titleCollection.reloadData()
        self.pagerView.reloadData()
        
        // Render theses collections
        for i in 0..<collections.count {
            self.collectionViews[i].render(places: collections[i].places)
        }
    }
    
    // MARK: - Linear title Collection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverCollectionTitleCell", for: indexPath) as! DiscoverCollectionTitleCell
        cell.label.text = collections[indexPath.row].name
        cell.selected(select: selectedPage == indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = collections[indexPath.row].name
        let width = UILabel.textWidth(font: titleFont, text: text)
        return CGSize(width: width + 20, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedPage = indexPath.row
        pagerView.showPage(at: indexPath.row, animated: true)
        titleCollection.reloadData()
        collectionViews[indexPath.row].reloadData()
    }
    
    // MARK: - Linear Pager View
    func numberOfPages(in pagerView: MXPagerView) -> Int {
        return collections.count
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        return collectionViews[index]
    }
}

class DiscoverCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var places = [Place]()
    var rootDelegate: DiscoverViewDelegate!
    let width = UIScreen.main.bounds.width
    
    convenience init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        self.init(frame: CGRect.zero, collectionViewLayout: layout)
        
        // Setup view, delegate and data source
        self.showsVerticalScrollIndicator = false
        self.backgroundColor = UIColor.white
        dataSource = self
        delegate = self
        
        // Register theses card for reuse
        let nib = UINib(nibName: "DiscoverCards", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "DiscoverPlaceCardView")
    }
    
    func render(places: [Place]) {
        self.places = places
        self.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverPlaceCardView", for: indexPath) as! DiscoverPlaceCardView
        cell.render(place: places[indexPath.row])
        cell.imageView.kf.setImage(with: URL(string: "https://migrationology.smugmug.com/Singapore-2016/i-fDSC6zr/0/X3/singapore-food-guide-3-X3.jpg"))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.width
        return CGSize(width: width, height: width * 0.9)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        rootDelegate.present(place: places[indexPath.row])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        rootDelegate.contentViewDidScroll(scrollView: scrollView)
    }
}

/**
 Title cell for Discovery Page
 */
class DiscoverCollectionTitleCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    func selected(select: Bool) {
        if (select) {
            label.textColor = UIColor.black.withAlphaComponent(0.8)
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.35)
        }
    }
}

/**
 Designable search field for Discovery page
 */
@IBDesignable class DiscoverSearchField: UITextField {
    
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
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ?  placeholder! : "", attributes:[NSForegroundColorAttributeName: color])
    }
}

