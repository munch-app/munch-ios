//
// Created by Fuxing Loh on 2019-02-18.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import Crashlytics

class MunchCrash {
    static func record(error: Error) {
        Crashlytics.sharedInstance().recordError(error)
    }
}