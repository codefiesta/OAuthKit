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
class Keychain: OAuth.Storage, @unchecked Sendable {

    private let lock: NSLock = .init()
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = .init()
    public var account: String
    
    /// Initializes the keychain with an overridden accound identifier.
    /// - Parameter account: a key indicating the account owner. Ideally, use the application identifier for this value.
    required init(_ account: String) {
        assert(account.isNotEmpty, "❌ The account identifier cannot be empty.")
        self.account = account
    }

    /// Queries the keychain for keys.
    var keys: [String] {
        var results = [String]()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { pointer in
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer(pointer))
        }

        guard status == noErr else { return results }

        if let items = result as? [[String: Any]] {
            for item in items {
                if let key = item[kSecAttrAccount as String] as? String {
                    results.append(key)
                }
            }
        }
        return results.filter{ $0.starts(with: account)}.sorted{ $0 < $1}
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

        let data = try encoder.encode(value)
        
        let account = accountKey(key)
        deleteNoLock(account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Fetches a stored value from the keychain with the specified key and attempts to decode it from the implied generic.
    /// - Parameter key: the keychain key
    /// - Returns: the generic codeable for the specified key or nil if not found
    func get<T>(key: String) throws -> T? where T: Codable {

        lock.lock()
        defer { lock.unlock() }
        
        let account = accountKey(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { pointer in
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer(pointer))
        }

        guard status == noErr, let data = result as? Data else {
            return nil
        }

        let value = try? decoder.decode(T.self, from: data)
        return value
    }

    /// Clears the keychain
    /// - Returns: true if values were cleared, otherwise false.
    @discardableResult
    func clear() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var results: [Bool] = []
        for key in keys {
            results.append(deleteNoLock(key))
        }

        guard results.isNotEmpty else { return true }
        return results.allSatisfy{ $0 == true }
    }

    /// Deletes the value for the specified key.
    /// - Parameter key: the key to delete
    /// - Returns: true if able to delete from the keychain, otherwise false
    @discardableResult
    func delete(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let account = accountKey(key)
        return deleteNoLock(account)
    }

    /// Attempts to delete the value for the specifed key without a lock in place.
    /// - Parameter key: the key to delete
    /// - Returns: true if able to delete from the keychain, otherwise false
    @discardableResult
    private func deleteNoLock(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == noErr
    }
}
