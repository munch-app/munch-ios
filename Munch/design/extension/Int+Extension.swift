//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation

fileprivate let monthDayYear: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM dd, yyyy"
    return formatter
}()

extension Int {
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(self) / 1000)
    }

    var asMonthDayYear: String {
        return monthDayYear.string(from: self.date)
    }
}