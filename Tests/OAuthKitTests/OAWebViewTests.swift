//
//  OAWebViewTests.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

#if !os(tvOS)
import Foundation
@testable import OAuthKit
import SwiftUI
import Testing
import WebKit

@MainActor
@Suite("OAuthWebView Tests", .tags(.views))
final class OAWebViewTests {

    /// The mock url session that overrides the protocol classes with `OAuthTestURLProtocol`
    /// that will intercept all outbound requests and return mocked test data.
    private lazy var urlSession: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [OAuthTestURLProtocol.self]
        return .init(configuration: configuration)
    }()

    let oauth: OAuth
    let webView: OAWebView

    /// Initializer.
    init() async throws {
        oauth = .init(.module)
        webView = .init()
        oauth.urlSession = urlSession
    }

    /// Tests the oauth environment values are correct.
    /// This is kind of a lame test but but provides code coverage for that extension.
    @Test("OAuth EnvironmentValues")
    func testEnvironmentValues() async throws {
        var values: EnvironmentValues = .init()
        values.oauth = oauth
        let environmentOAuth = values.oauth
        #expect(environmentOAuth == oauth)
    }

    /// Tests the OAWebViewCoordinator coordinator policy decision.
    /// TODO: This is fairly limited at the moment because we will receive errors
    /// about accessing the `oauth` environment outside of being installed on a view.
    /// Needs more investigation for testing SwiftUI views.
    @Test("Coordinator Policy Decisons")
    func whenCoordinatorDecidingPolicy() async throws {

        let coordinator: OAWebViewCoordinator = .init(oauth: oauth)
        let wkWebView = webView.view

        var urlRequest: URLRequest = .init(url: URL(string: "https://github.com/codefiesta/OAuthKit")!)
        urlRequest.url = nil

        // 1) Bad Request Expectations
        var navigationAction: WKNavigationAction = OAuthTestWKNavigationAction(urlRequest: urlRequest)
        var policy = await coordinator.webView(wkWebView, decidePolicyFor: navigationAction)
        #expect(policy == .cancel)

        let provider = oauth.providers[0]

        // 2) Authorization Code Expectations
        let state: String = .secureRandom()
        let code: String = .secureRandom()

        oauth.authorize(provider: provider, grantType: .authorizationCode(state))
        coordinator.update(state: oauth.state)
        var urlString = provider.redirectURI! + "?code=\(code)&state=\(state)"
        urlRequest = .init(url: URL(string: urlString)!)

        navigationAction = OAuthTestWKNavigationAction(urlRequest: urlRequest)
        policy = await coordinator.webView(wkWebView, decidePolicyFor: navigationAction)
        #expect(policy == .allow)

        // 3) PKCE Expectations
        let pkce: OAuth.PKCE = .init()
        oauth.authorize(provider: provider, grantType: .pkce(pkce))
        coordinator.update(state: oauth.state)
        urlString = provider.redirectURI! + "?code=\(code)&state=\(pkce.state)"
        urlRequest = .init(url: URL(string: urlString)!)

        navigationAction = OAuthTestWKNavigationAction(urlRequest: urlRequest)
        policy = await coordinator.webView(wkWebView, decidePolicyFor: navigationAction)
        #expect(policy == .allow)
    }
}
#endif
