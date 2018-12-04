//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import UIKit

extension UICollectionView {

    func register<T: UICollectionViewCell>(type: T.Type) {
        let identifier = String(describing: type)
        self.register(type, forCellWithReuseIdentifier: identifier)
    }

    func dequeue<T: UICollectionViewCell>(type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type)
        return self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
    }
}