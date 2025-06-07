//
//  OAuthTestWKNavigationAction.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

#if !os(tvOS)
import WebKit

/// OAuth Test WKNavigationAction that can be used for testing
final class OAuthTestWKNavigationAction: WKNavigationAction {

    /// The url request
    let urlRequest: URLRequest

    /// The url request accessor to adhere to WKNavigationAction protocol.
    override var request: URLRequest { urlRequest }

    /// The received policy
    var receivedPolicy: WKNavigationActionPolicy?

    /// Initializer with url request
    /// - Parameter urlRequest: the url request
    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
        super.init()
    }

    /// Returns the received decision policy
    /// - Parameter policy: the navigation action policy
    func decisionHandler(_ policy: WKNavigationActionPolicy) {
        receivedPolicy = policy
    }
}
#endif
