//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit

class DiscoverViewController: UIViewController {
    
    let client = MunchClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        client.discover(spatial: Spatial(lat: 1.297473,lng:  103.786620)){ meta, places in
            if (meta.isOk()){
                for place in places {
                    print(place.name)
                }
            }else{
                self.present(meta.createAlert(), animated: true, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
