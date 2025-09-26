//
//  Keychain.swift
//
//
//  Created by Kevin McKee
//

import Foundation
import Security

/// The default application tag to use.
private let defaultApplicationTag = "oauthkit"
/// The default token identifier suffix.
private let tokenIdentifier = "oauth-token"

/// A helper class used to interact with  Keychain access.
class Keychain: @unchecked Sendable {

    static let `default`: Keychain = Keychain()
    private let lock = NSLock()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var applicationTag: String = defaultApplicationTag

    private init() { }

    /// Initializes the keychain with an overridden application tag.
    /// - Parameter applicationTag: the application tag to use. Ideally, use the application identifier for this value.
    public init(_ applicationTag: String) {
        self.applicationTag = applicationTag
    }

    /// Queries the keychain for keys.
    var keys: [String] {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { pointer in
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer(pointer))
        }

        guard status == noErr else { return [] }

        var results = [String]()
        if let items = result as? [[String: Any]] {
            for item in items {
                if let key = item[kSecAttrAccount as String] as? String {
                    results.append(key)
                }
            }
        }

        return results.filter{ $0.starts(with: applicationTag)}.sorted{ $0 < $1}
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

        let account = accountKey(key)
        deleteNoLock(account)

        let data = try encoder.encode(value)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Fetches a storeed value from the keychain with the specified key and attempts to decode it from the implied generic.
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

    /// Builds the account key by prefixing the specified key with the application tag.
    /// - Parameter key: the key to prefix.
    /// - Returns: the unique account key to use
    private func accountKey(_ key: String) -> String {
        applicationTag + "." + key + "." + tokenIdentifier
    }
}
