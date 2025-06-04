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

    /// Initializer.
    init() async throws {
        oauth = .init(.module)
        // Override the url session
        oauth.urlSession = urlSession
    }

    /// Tests the OAWebViewCoordinator coordinator policy decision.
    /// TODO: This is fairly limited at the moment because we will receive errors
    /// about accessing the `oauth` environment outside of being installed on a view.
    /// Needs more investigation for testing SwiftUI views.
    @Test("Coordinator Policy Decisons")
    func whenCoordinatorDecidingPolicy() async throws {

        let webView: OAWebView = .init()
        let coordinator: OAWebViewCoordinator = webView.makeCoordinator()
        let wkWebView = webView.view

        var urlRequest: URLRequest = .init(url: URL(string: "https://github.com/codefiesta/OAuthKit")!)
        urlRequest.url = nil

        let navigationAction: WKNavigationAction = OAuthTestWKNavigationAction(urlRequest: urlRequest)
        let policy = await coordinator.webView(wkWebView, decidePolicyFor: navigationAction)
        #expect(policy == .cancel)
    }
}
#endif
