//
//  KeychainTests.swift
//  
//
//  Created by Kevin McKee on 5/29/24.
//

@testable import OAuthKit
import XCTest

final class KeychainTests: XCTestCase {

    override func tearDown() {
        Keychain.default.clear()
    }

    /// Tests default keychain storage.
    func testDefaultKeychain() {
        let keychain = Keychain.default
        let key = "Github"
        let token = OAuth.Token(accessToken: "1234", refreshToken: nil, expiresIn: 3600, state: "x", type: "bearer")

        let inserted = try! keychain.set(token, for: key)
        XCTAssertTrue(inserted)
        guard let found: OAuth.Token = try! keychain.get(key: key) else {
            XCTFail("No token found!")
            return
        }
        XCTAssertNotNil(token.accessToken)
        XCTAssertEqual(token.accessToken, found.accessToken)
        XCTAssertEqual(token.expiresIn, found.expiresIn)
        XCTAssertEqual(token.state, found.state)
        XCTAssertEqual(token.type, found.type)

        let keys = keychain.keys.filter{ $0.contains("oauth")}
        debugPrint("🔐", keys)
        XCTAssertGreaterThan(keys.count, 0)

        let deleted = keychain.delete(key: key)
        XCTAssertTrue(deleted)
    }
}

