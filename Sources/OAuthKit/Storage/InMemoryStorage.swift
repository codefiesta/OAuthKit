//
//  InMemoryStorage.swift
//  OAuthKit
//
//  Created by Kevin McKee on 9/24/26.
//

import Foundation

/// A storage implementation that holds all of the tokens in-memory. 
class InMemoryStorage: OAuth.Storage, @unchecked Sendable {

    public let account: String
    private var values: [String: Codable] = .init()
    private let lock: NSLock = .init()

    /// Initializes the storage with an account identifier.
    /// - Parameter account: a key indicating the account owner. Ideally, use the application identifier for this value.
    required init(_ account: String) {
        assert(account.isNotEmpty, "❌ The account identifier cannot be empty.")
        self.account = account
    }

    var keys: [String] {
        values.keys.sorted()
    }

    /// Sets the value for the specified key.
    /// - Parameters:
    ///   - value: the value to store
    ///   - key: the key to use
    /// - Returns: true if able to set the value, otherwise false
    @discardableResult
    func set(_ value: Codable, for key: String) throws -> Bool {
        assert(key.isNotEmpty, "❌ The keychain key cannot be empty.")
        lock.lock()
        defer { lock.unlock() }

        let key = accountKey(key)
        values[key] = value
        return true
    }

    /// Fetches a stored value from storage with the specified key and attempts to decode it from the implied generic.
    /// - Parameter key: the storage key
    /// - Returns: the generic codeable for the specified key or nil if not found
    func get<T>(key: String) throws -> T? where T: Codable {
        lock.lock()
        defer { lock.unlock() }

        let key = accountKey(key)
        return values[key] as? T
    }

    /// Clears all values from storage
    /// - Returns: true if values were cleared, otherwise false.
    @discardableResult
    func clear() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        values.removeAll()
        return true
    }

    /// Deletes the value for the specified key.
    /// - Parameter key: the key to delete
    /// - Returns: true if able to delete from the keychain, otherwise false
    @discardableResult
    func delete(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let key = accountKey(key)
        values.removeValue(forKey: key)
        return true
    }
}
