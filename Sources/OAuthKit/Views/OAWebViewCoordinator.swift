//
//  OAWebViewCoordinator.swift
//  
//
//  Created by Kevin McKee on 5/16/24.
//

import Combine
import SwiftUI
import WebKit

public class OAWebViewCoordinator: NSObject, WKNavigationDelegate {

    var webView: OAWebView

    /// The oauth reference.
    var oauth: OAuth {
        return webView.oauth
    }

    /// The current oauth provider the webview is interacting with.
    var provider: OAuth.Provider?

    /// Combine Subscribers which drive oauth events.
    var subscribers = Set<AnyCancellable>()

    init(_ webView: OAWebView) {
        self.webView = webView
        super.init()
        switch oauth.state {
        case .empty, .requestingAccessToken, .authorized:
            break
        case .authorizing(let provider):
            self.provider = provider
            guard let request = provider.request(grantType: .authorizationCode) else { return }
            self.webView.view.load(request)
        }

        // Subsribe to oauth state
        oauth.$state.sink { state in
            self.handle(state: state)
        }.store(in: &subscribers)
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme else {
            decisionHandler(.cancel)
            return
        }
        let urlComponents = URLComponents(string: url.absoluteString)
        if let queryItems = urlComponents?.queryItems {
            if let provider, let code = queryItems.filter({ $0.name == "code"}).first?.value {
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
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }

    /// Handles OAuth state changes.
    /// - Parameter state: the published state change.
    private func handle(state: OAuth.State) {
    }

}

extension OAWebViewCoordinator {

#if os(iOS) || os(visionOS)
#elseif os(macOS)

#endif

}
