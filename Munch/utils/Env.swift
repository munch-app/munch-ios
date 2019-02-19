//
// Created by Fuxing Loh on 2019-02-16.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation

struct Env {

    private static let production: Bool = {
        #if DEBUG
        print("DEBUG")
        return false
        #elseif ADHOC
        print("ADHOC")
        return false
        #else
        print("PRODUCTION")
        return true
        #endif
    }()

    static func isProduction() -> Bool {
        return self.production
    }

}