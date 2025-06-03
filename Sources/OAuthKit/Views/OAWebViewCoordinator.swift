//
//  OAWebViewCoordinator.swift
//  
//
//  Created by Kevin McKee on 5/16/24.
//

#if !os(tvOS)
import Combine
import SwiftUI
import WebKit

@MainActor
public class OAWebViewCoordinator: NSObject {

    var webView: OAWebView

    /// The oauth reference.
    var oauth: OAuth {
        webView.oauth
    }

    /// Initializer
    /// - Parameter webView: the webview that is being coordinated.
    init(_ webView: OAWebView) {
        self.webView = webView
        super.init()
    }

    /// Handles the authorization url for the specified provider.
    /// - Parameters:
    ///   - url: the url to handle
    ///   - provider: the oauth provider
    ///   - grantType: the grant type to handle
    private func handle(url: URL, provider: OAuth.Provider, grantType: OAuth.GrantType) {

        guard let redirectURI = provider.redirectURI, url.absoluteString.starts(with: redirectURI) else { return }
        let urlComponents = URLComponents(string: url.absoluteString)
        let queryItems = urlComponents?.queryItems ?? []
        guard queryItems.isNotEmpty else { return }
        guard let code = queryItems.filter({ $0.name == "code"}).first?.value else { return }
        guard let state = queryItems.filter({ $0.name == "state"}).first?.value else { return }

        switch grantType {
        case .authorizationCode(let authCodeState):

            // Verify the state
            guard state == authCodeState else {
                debugPrint("⚠️ State mismatch, expected [\(authCodeState)], received [\(state)]")
                return
            }

            if provider.debug {
                debugPrint("➡️ [AuthorizationCode], [\(url.absoluteString)], [\(code)]")
            }
            // Exchange the code for a token
            oauth.token(provider: provider, code: code)
        case .clientCredentials:
            break
        case .deviceCode:
            break
        case .pkce(let pkce):
            // Verify the state
            guard state == pkce.state else {
                debugPrint("⚠️ State mismatch, expected [\(pkce.state)], received [\(state)]")
                return
            }
            if provider.debug {
                debugPrint("➡️ [PKCE], [\(url.absoluteString)], [\(code)]")
            }
            // Exchange the code for a token along with the pkce validation data
            oauth.token(provider: provider, code: code, pkce: pkce)
        case .refreshToken:
            break
        }
    }

    /// Handles oauth state changes.
    /// - Parameter state: the published state change.
    func update(state: OAuth.State) {
        switch state {
        case .empty, .authorized, .requestingAccessToken, .requestingDeviceCode:
            break
        case .authorizing(let provider, let grantType):
            // Override the custom user agent for the provider and tell the browser to load the request
            webView.view.customUserAgent = provider.customUserAgent
            // Tell the webView to load the authorization request
            guard let request = OAuth.Request.auth(provider: provider, grantType: grantType) else { return }
            webView.view.load(request)
        case .receivedDeviceCode(let provider, let deviceCode):
            // Override the custom user agent for the provider and tell the browser to load the request
            webView.view.customUserAgent = provider.customUserAgent
            // Tell the webView to load the device code verification request
            guard let url = URL(string: deviceCode.verificationUri) else { return }
            let request = URLRequest(url: url)
            webView.view.load(request)
        }
    }
}

extension OAWebViewCoordinator: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .cancel
        }
        switch oauth.state {
        case .empty, .requestingAccessToken, .authorized, .requestingDeviceCode, .receivedDeviceCode:
            break
        case .authorizing(let provider, let grantType):
            handle(url: url, provider: provider, grantType: grantType)
        }
        return .allow
    }
}

#endif
