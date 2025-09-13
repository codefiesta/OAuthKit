//
//  OAuth+GrantType.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// Provides an enum representation for the OAuth 2.0 Grant Types.
    public enum GrantType: Equatable, Sendable {

        /// The OAuth 2.0 authorization code workflow.
        /// See RFC 6749 Standard [OAuth 2.0 Authorization Code Grant Type](https://datatracker.ietf.org/doc/html/rfc6749#section-1.3.1)
        /// - Parameters:
        ///   - String: the state verification string used to prevent CSRF attacks
        case authorizationCode(String)

        /// The OAuth 2.0 client credentials grant.
        /// See RFC 6749 Standard [OAuth 2.0 Client Credentials Code Grant Type](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4)
        case clientCredentials

        /// The OAuth 2.0 device authorization grant.
        /// See RFC 6749 Standard  [OAuth 2.0 Device Code Grant Type](https://datatracker.ietf.org/doc/html/rfc8628#section-3.4)
        case deviceCode

        /// The OAuth 2.0 Proof Key for Code Exchange is an extension to the Authorization Code
        /// flow to prevent CSRF and authorization code injection attacks. See RFC 7636 Standard  [OAuth 2.0 Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636)
        /// - Parameters:
        ///   - PKCE: the PKCE data
        case pkce(PKCE)

        /// The OAuth 2.0 Refresh Token grant type is used by clients to exchange a refresh token for an access token when the access token has expired.
        /// See RFC 6749 Standard  [OAuth 2.0 Refresh Token](https://datatracker.ietf.org/doc/html/rfc6749#section-1.5)
        case refreshToken

        /// The raw string value for a grant type.
        public var rawValue: String {
            switch self {
            case .authorizationCode:
                "authorization_code"
            case .clientCredentials:
                "client_credentials"
            case .deviceCode:
                "device_code"
            case .pkce:
                "pkce"
            case .refreshToken:
                "refresh_token"
            }
        }
    }
}
