//
//  StorageTests.swift
//  
//
//  Created by Kevin McKee
//

@testable import OAuthKit
import Testing

@Suite("Storage Tests", .tags(.storage))
final class StorageTests {

    let keychain: Keychain
    let inMemoryStorage: InMemoryStorage

    deinit {
        keychain.clear()
        inMemoryStorage.clear()
    }

    /// Initializer.
    init() async throws {
        let tag: String = "oauthkit.test." + .secureRandom()
        keychain = .init(tag)
        inMemoryStorage = .init(tag)
    }

    @Test("Storing keychain values")
    func whenStoringKeychainValues() async throws {
        let key = "Github"
        let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: .secureRandom(), expiresIn: 3600, scope: "email", type: "Bearer")

        let inserted = try! keychain.set(token, for: key)
        #expect(inserted == true)

        let found: OAuth.Token = try! keychain.get(key: key)!

        #expect(token.accessToken.isNotEmpty)
        #expect(token.accessToken == found.accessToken)
        #expect(token.expiresIn == found.expiresIn)
        #expect(token.scope == found.scope)
        #expect(token.type == found.type)

        let keys = keychain.keys
        debugPrint("🔐", keys)
        #expect(keys.count == 1)

        let deleted = keychain.delete(key: key)
        #expect(deleted == true)
        #expect(keychain.keys.count == 0)
    }

    @Test("Storing in-memory values")
    func whenStoringInMemoryValues() async throws {
        let key = "Github"
        let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: .secureRandom(), expiresIn: 3600, scope: "email", type: "Bearer")

        let inserted = try! inMemoryStorage.set(token, for: key)
        #expect(inserted == true)

        let found: OAuth.Token = try! inMemoryStorage.get(key: key)!

        #expect(token.accessToken.isNotEmpty)
        #expect(token.accessToken == found.accessToken)
        #expect(token.expiresIn == found.expiresIn)
        #expect(token.scope == found.scope)
        #expect(token.type == found.type)

        let keys = inMemoryStorage.keys
        debugPrint("🔐", keys)
        #expect(keys.count == 1)

        let deleted = inMemoryStorage.delete(key: key)
        #expect(deleted == true)
        #expect(inMemoryStorage.keys.count == 0)
    }

}
