//
// Created by Fuxing Loh on 18/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Array {

    // Safely lookup an index that might be out of bounds,
    // returning nil if it does not exist
    func get(_ index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
}

extension Calendar {
    static func millis(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents(Set<Calendar.Component>([.nanosecond]), from: from, to: to).nanosecond! / 1000000
    }

    static func micro(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents(Set<Calendar.Component>([.nanosecond]), from: from, to: to).nanosecond! / 1000
    }
}

extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}

extension Date {
    var millis: Int {
        return Int(self.timeIntervalSince1970 * 1000)
    }

    static var currentMillis: Int {
        return Date().millis
    }
}