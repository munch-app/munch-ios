//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 17/7/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import RealmSwift
import NVActivityIndicatorView

/**
 All classes that need discover delegate can extend this and will get the delegate
 */
protocol ContainDiscoverDelegate {
    var discoverDelegate: DiscoverDelegate! { get set }
}

class DiscoverLoadingController: UIViewController {
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init Loading indicator view
        self.indicatorView.color = .primary700
        self.indicatorView.startAnimating()
    }
}

class DiscoverSearchController: UIViewController, UITableViewDataSource, UITableViewDelegate, ContainDiscoverDelegate {
    var discoverDelegate: DiscoverDelegate!
    var searchDelegate: SearchNavigationBarDelegate!
    
    var searchBar: SearchNavigationBar {
        return discoverDelegate.searchBar
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var historyList = [QueryHistory]()
    var suggestList = [SearchResult]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        
        let realm = try! Realm()
        for history in realm.objects(QueryHistory.self).sorted(byKeyPath: "queryDate", ascending: false) {
            self.historyList.append(history)
        }
        
        self.textFieldAddTarget()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        let footerView = UIView(frame: .zero)
        footerView.backgroundColor = .white
        self.tableView.tableFooterView = footerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Popular Queries, TODO
        // Suggested Result
        // Recent Query
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 0
        case 1: return suggestList.count
        case 2: return historyList.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return nil
        case 1: return suggestList.isEmpty ? nil : "SUGGESTIONS"
        case 2: return historyList.isEmpty ? nil : "RECENT SEARCH"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = UIColor(hex: "F1F1F1")
        header.textLabel!.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSuggestCell") as! SearchSuggestCell
            let result = suggestList.get(indexPath.row)
            if let place = result as? Place {
                cell.render(text: place.name, type: "PLACE")
            } else if let location = result as? Location {
                cell.render(text: location.name, type: "LOCATION")
            } else {
                cell.render(text: nil, type: nil)
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchHistoryCell") as! SearchHistoryCell
            cell.render(text: historyList.get(indexPath.row)?.query)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            break
        case 1:
            apply(result: suggestList.get(indexPath.row)!)
            break
        case 2:
            apply(query: historyList.get(indexPath.row)!.query)
            break
        default:
            break
        }
    }
}

/**
 For text field delegate
 */
extension DiscoverSearchController {
    func textFieldAddTarget(){
        // Register targets for searchField
        searchBar.searchField.addTarget(self, action:#selector(textFieldChanged(_:)), for: .editingChanged)
        searchBar.searchField.addTarget(self, action:#selector(textFieldShouldReturn(_:)), for: .editingDidEndOnExit)
    }
    
    func textFieldChanged(_ sender: Any) {
        if let text = searchBar.searchField.text {
            suggestList.removeAll()
            tableView.reloadData()
            
            if (text.characters.count >= 3) {
                MunchApi.discovery.suggest(text: text, size: 15) { (meta, results) in
                    self.suggestList = results
                    self.tableView.reloadData()
                }
            }
        } else {
            suggestList.removeAll()
            tableView.reloadData()
        }
    }
    
    func textFieldShouldReturn(_ sender: Any) -> Bool {
        if let text = self.searchBar.searchField.text {
            // Persist query history
            apply(query: text)
        } else {
            self.searchBar.searchBarWillEnd(withReturn: true)
        }
        return true
    }
}

/**
 Before exit, must apply search bar
 Else changes won't be persisted when searched
 */
extension DiscoverSearchController {
    func apply(query: String) {
        persistHistory(query: query)
        self.searchBar.searchField.text = query
        self.searchBar.searchBarWillEnd(withReturn: true)
    }
    
    func apply(result: SearchResult) {
        if let place = result as? Place {
            // Present Place Result Directly
            self.searchBar.searchField.resignFirstResponder()
            self.discoverDelegate.present(place: place)
        } else if let location = result as? Location {
            // Apply Location to Search Result and End
            self.discoverDelegate.searchBar.searchField.text = nil
            self.discoverDelegate.searchBar.apply(location: location)
            self.searchBar.searchBarWillEnd(withReturn: false)
        }
    }
    
    /**
     Add new history to realm
     If history already exist, update the queryDate
     */
    func persistHistory(query: String) {
        // Don't Persist Empty Query
        if (query.isEmpty) { return }
        
        let realm = try! Realm()
        if let exist = realm.objects(QueryHistory.self).filter("query == '\(query)'").first {
            try! realm.write {
                exist.queryDate = Int(Date().timeIntervalSince1970)
            }
        } else {
            try! realm.write {
                let history = QueryHistory()
                history.query = query
                history.queryDate = Int(Date().timeIntervalSince1970)
                
                realm.add(history)
                let saved = realm.objects(LocationHistory.self).sorted(byKeyPath: "queryDate", ascending: false)
                // Delete if more then 20
                if (saved.count > 20) {
                    for (index, element) in saved.enumerated() {
                        if (index > 20) {
                            realm.delete(element)
                        }
                    }
                }
            }
        }
    }
}

class SearchSuggestCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    func render(text: String?, type: String? = nil) {
        self.titleLabel.text = text
        self.typeLabel.text = type
    }
}

class SearchHistoryCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    func render(text: String?) {
        self.titleLabel.text = text
    }
}

class QueryHistory: Object {
    dynamic var query: String = ""
    dynamic var queryDate = Int(Date().timeIntervalSince1970)
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
protocol ExtendedDiscoverDelegate: ContainDiscoverDelegate, DiscoverDelegate {
}

extension ExtendedDiscoverDelegate {
    var searchBar: SearchNavigationBar! {
        return self.discoverDelegate.searchBar
    }
    
    func present(place: Place) {
        self.discoverDelegate.present(place: place)
    }
    
    func collectionViewDidScrollFinish(_ scrollView: UIScrollView) {
        self.discoverDelegate.collectionViewDidScrollFinish(scrollView)
    }
}

class DiscoverTabController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CollectionController {
    var discoverDelegate: DiscoverDelegate!
    var collectionController: CardCollectionController!
    
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

extension DiscoverTabController: ExtendedDiscoverDelegate {
    func collectionViewDidScroll(_ scrollView: UIScrollView) {
        self.discoverDelegate.collectionViewDidScroll(scrollView)
        self.extendedBarHeightConstraint.constant = self.searchBar.height + 50
    }
    
    var headerHeight: CGFloat {
        return self.discoverDelegate.headerHeight + 50
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

class DiscoverTablessController: UIViewController, CollectionController {
    var discoverDelegate: DiscoverDelegate!
    var collectionController: CardCollectionController!
    
    @IBOutlet weak var collectionButton: UIButton!
    
    @IBOutlet weak var extendedBarHeightConstraint: NSLayoutConstraint!
    var collection: CardCollection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     Render collections view
     */
    func render(collections: [CardCollection]) {
        self.collection = collections[0]
        self.collectionController.render(collection: collection)
        if let title = collection.name {
            collectionButton.setTitle(title, for: .normal)
        } else {
            collectionButton.setTitle("Search Result", for: .normal)
        }
    }
    
    @IBAction func actionOnTitle(_ sender: Any) {
        self.collectionController.collectionView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CardCollectionController {
            self.collectionController = controller
            controller.discoverDelegate = self
        }
    }
}

extension DiscoverTablessController: ExtendedDiscoverDelegate {
    func collectionViewDidScroll(_ scrollView: UIScrollView) {
        self.discoverDelegate.collectionViewDidScroll(scrollView)
        let height = self.searchBar.height + 12
        let minHeight = SearchNavigationBar.minHeight + 45
        if (height <= minHeight) {
            self.extendedBarHeightConstraint.constant = minHeight
        } else {
            self.extendedBarHeightConstraint.constant = height
        }
    }
    
    var headerHeight: CGFloat {
        return self.discoverDelegate.headerHeight + 12
    }
}
