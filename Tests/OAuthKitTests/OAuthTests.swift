//
//  OAuthTests.swift
//
//
//  Created by Kevin McKee
//
import Foundation
@testable import OAuthKit
import Testing

@Suite("OAuth Tests", .tags(.oauth))
final class OAuthTests {

    /// Tests the init method using a custom bundle.
    @Test("Initializing providers")
    func whenInitializing() async throws {
        let oauth: OAuth = .init(.module)
        let providers = oauth.providers
        #expect(providers.isNotEmpty)
    }

    /// Tests the custom date extension operator.
    @Test("Expiring tokens")
    func whenExpiring() async throws {
        let expiresIn = 60
        let now = Date.now
        let issued = now.addingTimeInterval(-TimeInterval(expiresIn * 10)) // 10 minutes ago
        let expiration = issued.addingTimeInterval(TimeInterval(expiresIn))
        let timeInterval = expiration - Date.now
        #expect(timeInterval < 0)
    }
}
