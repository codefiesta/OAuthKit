//
//  Keychain+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee on 8/19/26.
//

import Foundation
#if canImport(Security)
import Security
#endif

/// The default account  to use.
private let defaultAccount = "oauthkit"
/// The default token identifier suffix.
private let tokenIdentifier = "oauth-token"

extension Keychain {

    // Provides the storage protocols used for storing sensitive data.
    // The storage operations should all be wrapped in a locking
    // mechanism to prevent any potential data races.
    protocol Storage {

        /// The owning account identifier.
        /// - Parameter account: a key indicating the account owner. Ideally, use the application identifier for this value.
        init(account: String)

        /// The account owner of this keychain storage.
        var account: String { get }

        /// Returns a list of keys owned by this account.
        var keys: [String] { get }

        /// Sets the data for the specified key
        /// - Parameters:
        ///   - data: the data to store for the specified key
        ///   - key: the key to use for the data
        /// - Returns: true if able to set the data, otherwise false
        func set(_ data: Data, for key: String) throws -> Bool

        /// Fetches storeed data from the data store with the specified key.
        /// - Parameter key: the keychain key
        /// - Returns: the data for the specified key or nil if not found
        func get(key: String) throws -> Data?

        /// Deletes the value for the specified key.
        /// - Parameter key: the key to delete
        /// - Returns: true if able to delete from the storage, otherwise false
        func delete(key: String) -> Bool

        /// Clears all values and keys for the current account.
        /// - Returns: true if values were cleared, otherwise false.
        func clear() -> Bool

        /// Builds the combined account key by prefixing the specified key with the account.
        /// - Parameter key: the key to prefix.
        /// - Returns: the unique account key to use
        func accountKey(_ key: String) -> String
    }

    #if canImport(Security)
    /// The default token storage used by Apple ecosystems.
    struct DefaultStorage: Storage {

        var account: String = defaultAccount

        init(account: String) {
            self.account = account
        }

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
        func set(_ data: Data, for key: String) throws -> Bool {
            assert(key.isNotEmpty, "❌ The keychain key cannot be empty.")

            let account = accountKey(key)
            delete(key: account)

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecValueData as String: data
            ]

            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        }

        /// Fetches storeed data from the data store with the specified key.
        /// - Parameter key: the keychain key
        /// - Returns: the data for the specified key or nil if not found
        func get(key: String) throws -> Data? {

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

            return data
        }

        /// Clears all values and keys for the current account.
        /// - Returns: true if values were cleared, otherwise false.
        @discardableResult
        func clear() -> Bool {

            var results: [Bool] = []
            for key in keys {
                results.append(delete(key: key))
            }

            guard results.isNotEmpty else { return true }
            return results.allSatisfy{ $0 == true }
        }

        /// Deletes the value for the specified key.
        /// - Parameter key: the key to delete
        /// - Returns: true if able to delete from the storage, otherwise false
        @discardableResult
        func delete(key: String) -> Bool {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            let status = SecItemDelete(query as CFDictionary)
            return status == noErr
        }
    }
    #endif
}

extension Keychain.Storage {

    /// Builds the combined account key by prefixing the specified key with the account.
    /// - Parameter key: the key to prefix.
    /// - Returns: the unique account key to use
    func accountKey(_ key: String) -> String {
        account + "." + key + "." + tokenIdentifier
    }
}
