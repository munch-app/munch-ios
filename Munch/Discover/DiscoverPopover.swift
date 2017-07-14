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
    @IBOutlet weak var searchBar: DiscoverSearchField!
    @IBOutlet weak var tableView: UITableView!
    
    var realm: Realm!
    var isSearchResult = false
    var historyList: [LocationHistory]!
    var searchList = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.realm = try! Realm()
        let results = realm.objects(LocationHistory.self).sorted(byKeyPath: "queryDate", ascending: false)
        self.historyList = Array(results)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar.becomeFirstResponder()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            // Detect my location section
            return 1
        } else {
            if (isSearchResult) {
                return searchList.count
            } else {
                return historyList.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            // Detect my location section
            return nil
        } else {
            if (isSearchResult) {
                return "Suggested Locations"
            } else {
                return "Recent Locations"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.font = UIFont.boldSystemFont(ofSize: 13)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.7)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            return tableView.dequeueReusableCell(withIdentifier: "LocationDetectMyCell") as! LocationDetectMyCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationTextCell") as! LocationTextCell
        if (isSearchResult) {
            cell.render(title: searchList.get(indexPath.row)?.name)
        } else {
            cell.render(title: historyList.get(indexPath.row)?.name)
        }
        return cell
    }
    
    @IBAction func textFieldChanged(_ sender: Any) {
        if let text = searchBar.text {
            searchList.removeAll()
            isSearchResult = true
            tableView.reloadData()
            
            if (text.characters.count >= 3) {
                MunchApi.locations.suggest(text: text) { (meta, locations) in
                    self.searchList = locations
                    self.isSearchResult = true
                    self.tableView.reloadData()
                }
            }
        } else {
            searchList.removeAll()
            isSearchResult = false
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0) {
            // TODO Click
        } else {
            if (isSearchResult) {
                if let location = searchList.get(indexPath.row) {
                    addToRealm(history: LocationHistory.create(from: location))
                    
                    // TODO Click
                }
            } else {
                if let history = historyList.get(indexPath.row) {
                    addToRealm(history: history)
                    // TODO Click
                }
            }
        }
    }
    
    /**
     Add new history to realm
     If history already exist, update the queryDate
     */
    func addToRealm(history: LocationHistory?) {
        if let history = history {
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

class LocationTextCell: UITableViewCell {
    @IBOutlet weak var locationLabel: UILabel!
    
    func render(title: String?) {
        self.locationLabel.text = title
    }
}

class LocationHistory: Object {
    dynamic var name: String = ""
    
    dynamic var json: String = ""
    dynamic var queryDate = Int(Date().timeIntervalSince1970)
    
    /**
     Create history from Location
     */
    class func create(from location: Location) -> LocationHistory? {
        if let name = location.name {
            let history = LocationHistory()
            history.name = name
            if let jsonData = try? JSONSerialization.data(withJSONObject: location.toParams(), options: []) {
                if let jsonText = String(data: jsonData, encoding: .ascii){
                    history.json = jsonText
                    return history
                }
            }
        }
        
        return nil
    }
}
