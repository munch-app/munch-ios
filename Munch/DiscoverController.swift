//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftLocation
import SDWebImage

class DiscoverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let client = MunchClient()
    
    @IBOutlet weak var discoverTableView: UITableView!
    var discoverPlaces = [Place]()
    var selectedIndex: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.discoverTableView.dataSource = self
        self.discoverTableView.delegate = self
        
        self.discover(lat: 1.298788, lng: 103.786759)
    }
    
    /**
     Discover local area
     */
    func discover(){
        SwiftLocation.Location.getLocation(accuracy: .block, frequency: .oneShot, success: {
            (_, location)  in
            let lat = location.coordinate.latitude
            let lng = location.coordinate.longitude
            self.discover(lat: lat, lng: lng)
        }) { (_, location, error) in
            let alert = UIAlertController(title: "Location Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /**
     Discover a defined latitude and longitude
     */
    func discover(lat: Double, lng: Double){
        client.discover(spatial: Spatial(lat: lat, lng: lng)){ meta, places in
            if (meta.isOk()){
                self.discoverPlaces.removeAll()
                self.discoverPlaces += places
                self.discoverTableView.reloadData()
            }else{
                self.present(meta.createAlert(), animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoverPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverViewCell", for: indexPath) as! DiscoverViewCell
        cell.render(place: discoverPlaces[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "segueToPlaceStoryboard", sender: self)
        self.selectedIndex = indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlaceViewController {
            controller.place = discoverPlaces[selectedIndex.row]
            discoverTableView.deselectRow(at: selectedIndex, animated: true)
        }
    }
}

class DiscoverViewCell: UITableViewCell {
    
    @IBOutlet weak var discoverImageView: UIImageView!
    
    @IBOutlet weak var placeName: UILabel!

    func render(place: Place) {
        self.placeName.text = place.name!
        if let imageUrl = place.images?.first?.url {
            self.discoverImageView.sd_setImage(with: URL(string: imageUrl))
        } else {
            self.discoverImageView.sd_setImage(with: nil)
        }
        
    }
}
