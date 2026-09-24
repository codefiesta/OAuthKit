//
//  OAuth+Storage.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

/// The default token identifier suffix.
private let tokenIdentifier = "oauth-token"

extension OAuth {

    // Provides the storage protocols used for storing token data.
    // The storage operations should all be wrapped in a locking
    // mechanism to prevent any potential data races.
    public protocol Storage: Sendable {

        /// The owning account identifier.
        /// - Parameter account: a key indicating the account owner. Ideally, use the application identifier for this value.
        init(_ account: String)

        /// The account owner of this keychain storage.
        var account: String { get }

        /// Returns a list of keys owned by this account.
        var keys: [String] { get }

        /// Sets the data for the specified key
        /// - Parameters:
        ///   - value: the value to store for the specified key
        ///   - key: the key to use for the data
        /// - Returns: true if able to set the data, otherwise false
        @discardableResult
        func set(_ value: Codable, for key: String) throws -> Bool

        /// Fetches storeed data from the storage with the specified key.
        /// - Parameter key: the keychain key
        /// - Returns: the data for the specified key or nil if not found
        func get<T>(key: String) throws -> T? where T: Codable

        /// Deletes the value for the specified key.
        /// - Parameter key: the key to delete
        /// - Returns: true if able to delete from the storage, otherwise false
        @discardableResult
        func delete(key: String) -> Bool

        /// Clears all values and keys for the current account.
        /// - Returns: true if values were cleared, otherwise false.
        @discardableResult
        func clear() -> Bool

        /// Builds the combined account key by prefixing the specified key with the account.
        /// - Parameter key: the key to prefix.
        /// - Returns: the unique account key to use
        func accountKey(_ key: String) -> String
    }
}

public extension OAuth.Storage {

    /// Builds the combined account key by prefixing the specified key with the account.
    /// - Parameter key: the key to prefix.
    /// - Returns: the unique account key to use
    func accountKey(_ key: String) -> String {
        account + "." + key + "." + tokenIdentifier
    }
}
