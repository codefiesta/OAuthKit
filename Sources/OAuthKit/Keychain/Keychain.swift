//
//  Keychain.swift
//
//
//  Created by Kevin McKee
//

import Foundation
#if canImport(Security)
import Security
#endif

/// A helper class used to interact with Keychain storage access. Wraps all storage write operations with threadsafe locks.
class Keychain: @unchecked Sendable {

    static let `default`: Keychain = Keychain()
    private let lock = NSLock()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var storage: Storage? = nil

    private init() { }

    /// Initializes the keychain with an overridden accound identifier.
    /// - Parameter account: a key indicating the account owner. Ideally, use the application identifier for this value.
    public init(_ account: String) {
        assert(account.isNotEmpty, "❌ The account identifier cannot be empty.")
        self.storage = DefaultStorage(account: account)
    }

    /// Queries the keychain for keys.
    var keys: [String] {
        storage?.keys ?? []
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

        guard let storage else { return false }
        let data = try encoder.encode(value)
        return try storage.set(data, for: key)
    }

    /// Fetches a stored value from the keychain with the specified key and attempts to decode it from the implied generic.
    /// - Parameter key: the keychain key
    /// - Returns: the generic codeable for the specified key or nil if not found
    func get<T>(key: String) throws -> T? where T: Codable {

        lock.lock()
        defer { lock.unlock() }

        guard let storage else { return nil }
        guard let data = try storage.get(key: key) else { return nil }
        let value = try? decoder.decode(T.self, from: data)
        return value
    }

    /// Clears the keychain
    /// - Returns: true if values were cleared, otherwise false.
    @discardableResult
    func clear() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage?.clear() ?? false
    }

    /// Deletes the value for the specified key.
    /// - Parameter key: the key to delete
    /// - Returns: true if able to delete from the keychain, otherwise false
    @discardableResult
    func delete(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let storage else { return false }
        let account = storage.accountKey(key)
        return storage.delete(key: account)
    }
}
