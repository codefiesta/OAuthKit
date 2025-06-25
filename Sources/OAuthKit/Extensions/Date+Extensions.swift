//
//  Date+Extensions.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Foundation

public extension Date {

    /// A custom operator that returns the timeinterval difference between the two dates.
    /// - Parameters:
    ///   - lhs: the left hand date
    ///   - rhs: the right hand date
    /// - Returns: the time interval between the two dates.
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
