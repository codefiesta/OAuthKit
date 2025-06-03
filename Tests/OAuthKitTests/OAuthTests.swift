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
        let state: String = .secureRandom(count: 16)
        let grantType: OAuth.GrantType = .authorizationCode(state)
        let request = OAuth.Request.auth(provider: provider, grantType: grantType)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id="))
        #expect(request!.url!.absoluteString.contains("redirect_uri=\(provider.redirectURI!)"))
        #expect(request!.url!.absoluteString.contains("response_type=code"))
        #expect(request!.url!.absoluteString.contains("state=\(state)"))
    }

    /// Tests the refresh token request parameters.
    @Test("Building Refresh Token Request")
    func whenBuildingRefreshTokenRequest() async throws {
        let provider = await oauth.providers[0]
        let token: OAuth.Token = .init(accessToken: UUID().uuidString, refreshToken: UUID().uuidString, expiresIn: 3600, scope: nil, type: "bearer")
        let request = OAuth.Request.refresh(provider: provider, token: token)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id="))
        #expect(request!.url!.absoluteString.contains("grant_type=refresh_token"))
        #expect(request!.url!.absoluteString.contains("refresh_token=\(token.refreshToken!)"))
    }

    /// Tests the PKCE request parameters.
    @Test("Building PKCE Request")
    func whenBuildingPKCERequest() async throws {
        let provider = await oauth.providers[0]
        let pkce: OAuth.PKCE = .init()
        let grantType: OAuth.GrantType = .pkce(pkce)
        let request = OAuth.Request.auth(provider: provider, grantType: grantType)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id="))
        #expect(request!.url!.absoluteString.contains("redirect_uri=\(provider.redirectURI!)"))
        #expect(request!.url!.absoluteString.contains("response_type=code"))
        #expect(request!.url!.absoluteString.contains("state=\(pkce.state)"))
        #expect(request!.url!.absoluteString.contains("code_challenge=\(pkce.codeChallenge)"))
        #expect(request!.url!.absoluteString.contains("code_challenge_method=\(pkce.codeChallengeMethod)"))
    }

    /// Tests to make sure the PKCE code verifier and challenge are correct.
    /// See: https://www.oauth.com/playground/authorization-code-with-pkce.html
    @Test("Generating PKCE Code Challenge")
    func whenGeneratingPKCECodeChallenge() async throws {
        let codeVerifier = "irYm7d4my6egZ-ea5jFnL9XM3CYshCdcbL3OlW0w7HMvcE5d"
        let codeChallenge = codeVerifier.sha256.base64URL
        let expectedResult = "W7BYCsNLCgzw-Kf5IZFjhwd-WdPZEhTNNJGQVgOq560"
        #expect(codeChallenge == expectedResult)
    }
}
