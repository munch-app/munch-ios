//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import UIKit

extension UITableView {

    func register<T: UITableViewCell>(type: T.Type) {
        let identifier = String(describing: type)
        self.register(type, forCellReuseIdentifier: identifier)
    }

    func dequeue<T: UITableViewCell>(type: T.Type) -> T {
        let identifier = String(describing: type)
        return self.dequeueReusableCell(withIdentifier: identifier) as! T
    }
}