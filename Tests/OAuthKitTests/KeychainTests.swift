//
//  KeychainTests.swift
//  
//
//  Created by Kevin McKee
//

@testable import OAuthKit
import Testing

@Suite("Keychain Tests", .tags(.keychain))
final class KeychainTests {

    deinit {
        Keychain.default.clear()
    }

    @Test("Storing keychain values")
    func whenStoring() async throws {
        let keychain = Keychain.default
        let key = "Github"
        let token = OAuth.Token(accessToken: "1234", refreshToken: nil, expiresIn: 3600, state: "x", type: "bearer")

        let inserted = try! keychain.set(token, for: key)
        #expect(inserted == true)

        let found: OAuth.Token = try! keychain.get(key: key)!

        #expect(token.accessToken != nil)
        #expect(token.accessToken == found.accessToken)
        #expect(token.expiresIn == found.expiresIn)
        #expect(token.state == found.state)
        #expect(token.type == found.type)

        let keys = keychain.keys.filter{ $0.contains("oauth")}
        debugPrint("🔐", keys)
        #expect(keys.count > 0)

        let deleted = keychain.delete(key: key)
        #expect(deleted == true)
    }
}
