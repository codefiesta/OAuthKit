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

    let oauth: OAuth

    /// Initializer.
    init() async throws {
        oauth = await .init(.module)
    }

    /// Tests the init method using a custom bundle.
    @Test("Initializing providers")
    func whenInitializing() async throws {
        let providers = await oauth.providers
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

    /// Tests the authorization request parameters.
    @Test("Building Authorization Request")
    func whenBuildingAuthorizationRequest() async throws {
        let provider = await oauth.providers[0]
        let request = provider.request(grantType: .authorizationCode)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id="))
        #expect(request!.url!.absoluteString.contains("redirect_uri=\(provider.redirectURI!)"))
        #expect(request!.url!.absoluteString.contains("response_type=code"))
    }

    /// Tests the refresh token request parameters.
    @Test("Building Refresh Token Request")
    func whenBuildingRefreshTokenRequest() async throws {
        let provider = await oauth.providers[0]
        let token: OAuth.Token = .init(accessToken: UUID().uuidString, refreshToken: UUID().uuidString, expiresIn: 3600, state: nil, type: "bearer")
        let request = provider.request(grantType: .refreshToken, token: token)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id="))
        #expect(request!.url!.absoluteString.contains("grant_type=refresh_token"))
        #expect(request!.url!.absoluteString.contains("refresh_token=\(token.refreshToken!)"))
    }
}
