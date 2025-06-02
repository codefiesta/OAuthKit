//
//  OAuth+GrantType.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// Provides an enum representation for the OAuth 2.0 Grant Types.
    /// 
    /// See: https://oauth.net/2/grant-types/
    public enum GrantType: Equatable, Sendable {

        /// The OAuth 2.0 authorization code workflow.
        /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-1.3.1
        /// - Parameters:
        ///   - String: the state verification string used to prevent CSRF attacks
        case authorizationCode(String)

        /// The OAuth 2.0 client credentials grant.
        /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-4.4
        case clientCredentials

        /// The OAuth 2.0 device authorization grant.
        /// See: https://datatracker.ietf.org/doc/html/rfc8628#section-3.4
        case deviceCode

        /// The OAuth 2.0 Proof Key for Code Exchange is an extension to the Authorization Code
        /// flow to prevent CSRF and authorization code injection attacks.
        /// - Parameters:
        ///   - PKCE: the PKCE data
        case pkce(PKCE)

        /// The OAuth 2.0 Refresh Token grant type is used by clients to exchange a refresh token for an access token when the access token has expired.
        /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-1.5
        case refreshToken

        /// The raw string value for a grant type.
        var rawValue: String {
            switch self {
            case .authorizationCode:
                return "code"
            case .clientCredentials:
                return "client_credentials"
            case .deviceCode:
                return "device_code"
            case .pkce:
                return "pkce"
            case .refreshToken:
                return "refresh_token"
            }
        }
    }
}
