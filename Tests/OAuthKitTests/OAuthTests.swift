//
//  OAuthTests.swift
//
//
//  Created by Kevin McKee
//
import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
@testable import OAuthKit
import Testing

@MainActor
@Suite("OAuth Tests", .tags(.oauth))
final class OAuthTests {

    let oauth: OAuth
    let tag: String
    var keychain: Keychain {
        oauth.keychain
    }
    var provider: OAuth.Provider {
        oauth.providers.filter{ $0.id == "GitHub" }.first!
    }

    /// The mock url session that overrides the protocol classes with `OAuthTestURLProtocol`
    /// that will intercept all outbound requests and return mocked test data.
    private static let urlSession: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [OAuthTestURLProtocol.self]
        return .init(configuration: configuration)
    }()

    /// Initializer.
    init() async throws {
        tag = "oauthkit.test." + .secureRandom()

        let options: [OAuth.Option: Any] = [
            .applicationTag: tag, .autoRefresh: true,
            .useNonPersistentWebDataStore: true,
            .urlSession: Self.urlSession,
        ]
        oauth = .init(.module, options: options)
        #expect(oauth.useNonPersistentWebDataStore == true)
        #expect(oauth.urlSession == Self.urlSession)
    }

    /// Tests the initialization with providers.
    @Test("When Initializing")
    func whenInitializing() async throws {
        let appTag: String = .secureRandom()
        let options: [OAuth.Option: Any] = [
            .applicationTag: appTag,
            .autoRefresh: true,
            .urlSession: Self.urlSession,
        ]
        let providers: [OAuth.Provider] = [
            .init(id: .secureRandom(),
                  authorizationURL: URL(string: "http://github.com/codefiesta/auth")!,
                  accessTokenURL: URL(string: "http://github.com/codefiesta/token")!,
                  clientID: .secureRandom(),
                  clientSecret: .secureRandom())
        ]
        let customOAuth: OAuth = .init(providers: providers, options: options)
        #expect(customOAuth.providers.count == 1)
        #expect(customOAuth.useNonPersistentWebDataStore == false)
        #expect(customOAuth.urlSession == Self.urlSession)
    }

    @Test("When Requiring Local Authentication")
    func whenRequiringAuthenticationWithBiometricsOrCompanion() async throws {
        let appTag: String = .secureRandom()
        var options: [OAuth.Option: Any] = [
            .applicationTag: appTag,
            .requireAuthenticationWithBiometricsOrCompanion: true,
            .autoRefresh: true
        ]
        #if !os(tvOS)
        options[.localAuthentication] = OAuthTestLAContext()
        #endif
        let customOAuth: OAuth = .init(.module, options: options)
        #expect(customOAuth.providers.isNotEmpty)
        #expect(customOAuth.requireAuthenticationWithBiometricsOrCompanion == true)
    }

    @Test("When Restoring Authorizations")
    func whenRestoringAuthorizations() async throws {
        let key = provider.id
        let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: .secureRandom(), expiresIn: 3600, scope: "email", type: "Bearer")
        let auth: OAuth.Authorization = .init(issuer: provider.id, token: token)
        let inserted = try! keychain.set(auth, for: key)
        #expect(inserted == true)

        let options: [OAuth.Option: Any] = [
            .applicationTag: tag,
            .autoRefresh: false,
            .useNonPersistentWebDataStore: true,
            .urlSession: Self.urlSession
        ]
        let restoredOAuth: OAuth = .init(.module, options: options)
        #expect(restoredOAuth.state == .authorized(provider, auth))
        keychain.clear()
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
        let state: String = .secureRandom(count: 16)
        let grantType: OAuth.GrantType = .authorizationCode(state)
        let request = OAuth.Request.auth(provider: provider, grantType: grantType)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id=\(provider.clientID)"))
        #expect(request!.url!.absoluteString.contains("redirect_uri=\(provider.redirectURI!)"))
        #expect(request!.url!.absoluteString.contains("response_type=code"))
        #expect(request!.url!.absoluteString.contains("state=\(state)"))
    }

    /// Tests the building of client credential token requests.
    @Test("Building Client Credentials Token Requests")
    func whenBuildingClientCredentialsTokenRequests() async throws {
        let request = OAuth.Request.token(provider: provider)
        let data = request?.httpBody
        let stringData = String(data: data!, encoding: .utf8)
        #expect(request != nil)
        #expect(data != nil)
        #expect(stringData!.contains("client_id="))
        #expect(stringData!.contains("client_secret="))
        #expect(stringData!.contains("grant_type=client_credentials"))
        oauth.authorize(provider: provider, grantType: .clientCredentials)
        let result = await waitForAuthorization(oauth)
        #expect(result == true)
    }

    /// Tests the `/device`code  request parameters.
    @Test("Building Device Code Request")
    func whenBuildingDeviceCodeRequest() async throws {
        let request = OAuth.Request.device(provider: provider)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id=\(provider.clientID)"))
        #expect(request!.url!.absoluteString.contains("client_secret=\(provider.clientSecret!)"))
        #expect(request!.url!.absoluteString.contains("grant_type=device_code"))
        oauth.authorize(provider: provider, grantType: .deviceCode)
    }

    /// Tests the building of device code token requests.
    @Test("Building Device Code Token Requests")
    func whenBuildingDeviceCodeTokenRequests() async throws {
        let deviceCode: OAuth.DeviceCode = .init(deviceCode: .secureRandom(), userCode: "ABC-XYZ", verificationUri: "https://example.com/device", expiresIn: 1800, interval: 5)
        let request = OAuth.Request.token(provider: provider, deviceCode: deviceCode)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id=\(provider.clientID)"))
        #expect(request!.url!.absoluteString.contains("device_code=\(deviceCode.deviceCode)"))
        #expect(request!.url!.absoluteString.contains("grant_type=\(OAuth.DeviceCode.grantType)"))
    }

    /// Tests the building of token requests.
    @Test("Building Token Requests")
    func whenBuildingTokenRequests() async throws {
        let code: String = .secureRandom()
        let request = OAuth.Request.token(provider: provider, code: code, pkce: nil)
        let data = request?.httpBody
        let stringData = String(data: data!, encoding: .utf8)
        #expect(request != nil)
        #expect(data != nil)
        #expect(stringData!.contains("client_id=\(provider.clientID)"))
        #expect(stringData!.contains("client_secret=\(provider.clientSecret!)"))
        #expect(stringData!.contains("code=\(code)"))
        #expect(stringData!.contains("redirect_uri=\(provider.redirectURI!)"))
        #expect(stringData!.contains("grant_type=authorization_code"))
        oauth.token(provider: provider, code: code, pkce: nil)
        let result = await waitForAuthorization(oauth)
        #expect(result == true)
    }

    /// Tests the building of PKCE token requests.
    @Test("Building PKCE Token Requests")
    func whenBuildingPKCETokenRequests() async throws {
        let code: String = .secureRandom()
        let pkce: OAuth.PKCE = .init()
        let request = OAuth.Request.token(provider: provider, code: code, pkce: pkce)
        let data = request?.httpBody
        let stringData = String(data: data!, encoding: .utf8)
        #expect(request != nil)
        #expect(data != nil)
        #expect(stringData!.contains("client_id=\(provider.clientID)"))
        if let clientSecret = provider.clientSecret {
            #expect(stringData!.contains("client_secret=\(clientSecret)"))
        }
        #expect(stringData!.contains("code=\(code)"))
        #expect(stringData!.contains("redirect_uri=\(provider.redirectURI!)"))
        #expect(stringData!.contains("grant_type=authorization_code"))
        #expect(stringData!.contains("code_verifier=\(pkce.codeVerifier)"))
        oauth.token(provider: provider, code: code, pkce: pkce)
        let result = await waitForAuthorization(oauth)
        #expect(result == true)
    }

    /// Tests the refresh token request parameters.
    @Test("Building Refresh Token Request")
    func whenBuildingRefreshTokenRequest() async throws {
        let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: .secureRandom(), expiresIn: 3600, scope: nil, type: "Bearer")
        let request = OAuth.Request.refresh(provider: provider, token: token)
        #expect(request != nil)
        #expect(request!.url!.absoluteString.contains("client_id="))
        #expect(request!.url!.absoluteString.contains("grant_type=refresh_token"))
        #expect(request!.url!.absoluteString.contains("refresh_token=\(token.refreshToken!)"))
        let auth: OAuth.Authorization = .init(issuer: provider.id, token: token)
        try! keychain.set(auth, for: provider.id)
        oauth.authorize(provider: provider, grantType: .refreshToken)
        let result = await waitForAuthorization(oauth)
        #expect(result == true)
    }

    @Test("When Auto Refreshng Tokens")
    func whenAutoRefreshingTokens() async throws {
        let key = provider.id
        let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: .secureRandom(), expiresIn: 0, scope: "email", type: "Bearer")
        let auth: OAuth.Authorization = .init(issuer: provider.id, token: token)
        let inserted = try! keychain.set(auth, for: key)
        #expect(inserted == true)

        let options: [OAuth.Option: Any] = [
            .applicationTag: tag,
            .autoRefresh: true,
            .useNonPersistentWebDataStore: true,
            .urlSession: Self.urlSession
        ]
        let restoredOAuth: OAuth = .init(.module, options: options)
        #expect(restoredOAuth.state == .authorized(provider, auth))
        restoredOAuth.state = .empty
        let result = await waitForAuthorization(restoredOAuth)
        #expect(result == true)
    }

    /// Tests the PKCE request parameters.
    @Test("Building PKCE Request")
    func whenBuildingPKCERequest() async throws {
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

    /// Tests OAuth Secure Random State Generation
    @Test("OAuth Polling for Device Code Authorization")
    private func whenPollingForDeviceCodeAuthorization() async throws {
        let deviceCode: OAuth.DeviceCode = .init(deviceCode: .secureRandom(), userCode: .secureRandom(), verificationUri: "https://example.com", expiresIn: 200, interval: 0)
        await oauth.poll(provider: provider, deviceCode: deviceCode)
        let result = await waitForAuthorization(oauth)
        #expect(result == true)
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

    /// Tests to make sure the grant type raw values are frozen and haven't been changed during development.
    @Test("Grant Type Raw Value Checking")
    func whenCheckingGrantType() async throws {
        var grantType: OAuth.GrantType = .authorizationCode(.empty)
        #expect(grantType.rawValue == "authorization_code")
        grantType = .clientCredentials
        #expect(grantType.rawValue == "client_credentials")
        grantType = .deviceCode
        #expect(grantType.rawValue == "device_code")
        grantType = .pkce(.init())
        #expect(grantType.rawValue == "pkce")
        grantType = .refreshToken
        #expect(grantType.rawValue == "refresh_token")
    }

    /// Tests the adding of the Authorization header to an URLRequest.
    @Test("Adding Authorization Header to URLRequest")
    func whenAddingAuthHeader() async throws {
        let string = "https://github.com/codefiesta/OAuthKit"
        let url = URL(string: string)
        var urlRequest = URLRequest(url: url!)

        let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: nil, expiresIn: 3600, scope: nil, type: "Bearer")
        let auth: OAuth.Authorization = .init(issuer: provider.id, token: token)
        #expect(auth.expiration != nil)
        #expect(auth.isExpired == false)
        urlRequest.addAuthorization(auth: auth)

        let header = urlRequest.value(forHTTPHeaderField: "Authorization")
        #expect(header != nil)
        #expect(header == "\(token.type) \(token.accessToken)")
    }

    /// Tests OAuth State changes
    @Test("OAuth State Changes")
    func whenOAuthState() async throws {
        let state: String = .secureRandom(count: 16)

        // Authorization Code
        var grantType: OAuth.GrantType = .authorizationCode(state)
        oauth.authorize(provider: provider, grantType: grantType)
        #expect(oauth.state == .authorizing(provider, grantType))

        // PKCE
        let pkce: OAuth.PKCE = .init()
        grantType = .pkce(pkce)
        oauth.authorize(provider: provider, grantType: grantType)
        #expect(oauth.state == .authorizing(provider, grantType))

        // Empty
        oauth.clear()
        #expect(oauth.state == .empty)
    }

    /// Tests OAuth Secure Random State Generation
    @Test("OAuth Secure Random State")
    func whenGeneratingOAuthSecureRandomState() async throws {
        let random = OAuth.secureRandom()
        #expect(random.count >= 43)
    }

    /// Streams the oauth status until we receive an authorization.
    /// This should only be used on test methods that expect an authorization to be inserted into the keychain.
    private func waitForAuthorization(_ oauth: OAuth) async -> Bool {
        let monitor: OAuth.Monitor = .init(oauth: oauth)
        for await state in monitor.stream {
            switch state {
            case .empty, .authorizing, .requestingAccessToken, .requestingDeviceCode, .receivedDeviceCode:
                break
            case .authorized(_, _):
                oauth.clear()
                return true
            }
        }
        return false
    }
}
