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
        return webView.oauth
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
    private func handle(url: URL, provider: OAuth.Provider) {
        debugPrint("👻", url.absoluteString)
        let urlComponents = URLComponents(string: url.absoluteString)
        if let queryItems = urlComponents?.queryItems {
            if let code = queryItems.filter({ $0.name == "code"}).first?.value {
                Task {
                    let result = await oauth.requestAccessToken(provider: provider, code: code)
                    switch result {
                    case .success(let token):
                        debugPrint("✅ [Received token]", token)
                    case .failure(let error):
                        debugPrint("💩 [Error requesting access token]", error)
                    }
                }
            }
        }
    }

    /// Handles oauth state changes.
    /// - Parameter state: the published state change.
    func update(state: OAuth.State) {
        switch state {
        case .empty, .authorized, .requestingAccessToken:
            break
        case .authorizing(let provider):
            guard let request = provider.request(grantType: .authorizationCode) else { return }
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
        case .empty, .requestingAccessToken, .authorized:
            break
        case .authorizing(let provider):
            handle(url: url, provider: provider)
        }
        return .allow
    }
}

#endif
