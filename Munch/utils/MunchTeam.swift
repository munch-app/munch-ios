//
// Created by Fuxing Loh on 2019-03-12.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation

class MunchTeam {
    private static let all = Set<String>([
        "oNOfWjsL49giM0", // YZ
        "sGtVZuFJwYhf5O", // FX
        "GoNd1yY0uVcA8p", // EL
        "CM8wAOSdenMD8d", // JD
        "0aMrslcgMyW3xb", // ST
    ])

    public class func isTeam(userId: String) -> Bool {
        let index = userId.index(userId.startIndex, offsetBy: 14)
        return all.contains(userId.substring(to: index))
    }
}