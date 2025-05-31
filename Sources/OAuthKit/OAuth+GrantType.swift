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
    public enum GrantType: String, Codable, Sendable {
        case authorizationCode
        case clientCredentials = "client_credentials"
        case deviceCode = "device_code"
        case pkce
        case refreshToken = "refresh_token"
    }
}
