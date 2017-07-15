//
//  DiscoverFilter.swift
//  Munch
//
//  Created by Fuxing Loh on 22/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import SwiftyJSON

class LocationDiscoverPopover: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var searchBar: SearchNavigationBar!
    @IBOutlet weak var searchField: DiscoverSearchField!
    @IBOutlet weak var tableView: UITableView!
    
    var realm: Realm!
    var historyList = [Location]()
    var suggestList = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        
        self.realm = try! Realm()
        for history in realm.objects(LocationHistory.self).sorted(byKeyPath: "queryDate", ascending: false) {
            if let data = history.data, let location = Location(json: JSON(data)) {
                self.historyList.append(location)
            }
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.tableFooterView?.backgroundColor = UIColor.white
        
        self.searchField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchField.resignFirstResponder()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Detect My Location
        // Popular Locations
        // Suggested Locations
        // Recent Locations
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return suggestList.isEmpty ? 1 : 0
        case 2: return suggestList.count
        case 3: return historyList.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return suggestList.isEmpty ? "POPULAR LOCATIONS" : nil
        case 2: return suggestList.isEmpty ? nil : "SUGGESTED LOCATIONS"
        case 3: return historyList.isEmpty ? nil : "RECENT LOCATIONS"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = UIColor(hex: "F9F9F9")
        header.textLabel!.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return tableView.dequeueReusableCell(withIdentifier: "LocationDetectMyCell")!
        case 1: return tableView.dequeueReusableCell(withIdentifier: "LocationPopularCell")!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationTextCell") as! LocationTextCell
            let name = suggestList.isEmpty ? historyList.get(indexPath.row)?.name : suggestList.get(indexPath.row)?.name
            cell.render(title: name)
            return cell
        }
    }
    
    @IBAction func textFieldChanged(_ sender: Any) {
        if let text = searchField.text {
            suggestList.removeAll()
            tableView.reloadData()
            
            if (text.characters.count >= 3) {
                MunchApi.locations.suggest(text: text) { (meta, locations) in
                    self.suggestList = locations
                    self.tableView.reloadData()
                }
            }
        } else {
            suggestList.removeAll()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            apply(location: nil)
            break
        case 2:
            apply(location: suggestList.get(indexPath.row))
            break
        case 3:
            apply(location: historyList.get(indexPath.row))
            break
        default:
            break
        }
    }
    
    /**
     Apply, click for location
     */
    func apply(location: Location?) {
        addToRealm(location: location)
        searchBar.apply(location: location)
        performSegue(withIdentifier: "unwindToDiscover", sender: nil)
    }
    
    /**
     Add new history to realm
     If history already exist, update the queryDate
     */
    func addToRealm(location: Location?) {
        if let history = LocationHistory.create(from: location) {
            if let exist = realm.objects(LocationHistory.self).filter("name == '\(history.name)'").first {
                try! realm.write {
                    exist.queryDate = Int(Date().timeIntervalSince1970)
                }
            } else {
                try! realm.write {
                    realm.add(history)
                }
            }
        }
    }
}

class LocationDetectMyCell: UITableViewCell {
    var needPrepare = true
    
    @IBOutlet weak var detectLocationButton: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (needPrepare){
            detectLocationButton.layer.cornerRadius = 4.0
            detectLocationButton.layer.borderWidth = 1.0
            detectLocationButton.layer.borderColor = UIColor(hex: "007AFF").cgColor
            needPrepare = false
        }
    }
}

class LocationPopularCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var cardCollections: UICollectionView!
    
    var locations = [Location]()
    var delegate: LocationDiscoverPopover?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.cardCollections.delegate = self
        self.cardCollections.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card = collectionView.dequeueReusableCell(withReuseIdentifier: "LocationPopularCellCard", for: indexPath) as! LocationPopularCellCard
        if let location = locations.get(indexPath.row) {
            card.render(location: location)
        }
        return card
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let location = locations.get(indexPath.row) {
            delegate?.apply(location: location)
        }
    }
    
    class LocationPopularCellCard: UICollectionViewCell {
        @IBOutlet weak var nameLabel: UILabel!
        @IBOutlet weak var distanceLabel: UILabel!
        
        func render(location: Location) {
            self.nameLabel.text = location.name
            if let latLng = location.center {
                self.distanceLabel.text = MunchLocation.distance(asMetric: latLng)
            }
        }
    }
}

class LocationTextCell: UITableViewCell {
    @IBOutlet weak var locationLabel: UILabel!
    
    func render(title: String?) {
        self.locationLabel.text = title
    }
}

class LocationHistory: Object {
    dynamic var name: String = ""
    
    dynamic var data: Data?
    dynamic var queryDate = Int(Date().timeIntervalSince1970)
    
    /**
     Create history from Location
     */
    class func create(from location: Location?) -> LocationHistory? {
        if let name = location?.name {
            let history = LocationHistory()
            history.name = name
            if let jsonData = try? JSONSerialization.data(withJSONObject: location!.toParams()) {
                history.data = jsonData
                return history
            }
        }
        
        return nil
    }
}
