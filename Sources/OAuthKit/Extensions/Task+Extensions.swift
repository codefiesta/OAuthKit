//
//  Task+Extensions.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Foundation

private let nanoSeconds: Double = 1_000_000_000

extension Task where Failure == Error {

    /// Builds a delayed task.
    /// - Parameters:
    ///   - delayInterval: the delay interval
    ///   - priority: the task priority
    ///   - operation: the task operation to execute
    /// - Returns: a new task that will execute after the specified delay
    static func delayed(
        byTimeInterval delayInterval: TimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {

        Task {
            let delay = UInt64(delayInterval * nanoSeconds)
            try await Task<Never, Never>.sleep(nanoseconds: delay)
            return try await operation()
        }
    }
}
