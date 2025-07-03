//
//  OAuth+Token.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// A codable type that holds oauth token information.
    /// - SeeAlso:
    /// [Access Token Response](https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/)
    public struct Token: Codable, Equatable, Sendable {

        /// The access token string as issued by the authorization server.
        public let accessToken: String

        /// If the access token will expire, then this can be used to obtain another access token.
        public let refreshToken: String?

        /// If the access token expires, this is the duration of time the access token is granted for (in seconds).
        public let expiresIn: Int?

        /// If the scope the user granted is identical to the scope the app requested, this parameter is optional.
        /// If the granted scope is different from the requested scope, such as if the user modified the scope, then this parameter is required.
        public let scope: String?

        /// The type of token this is, typically just the string “Bearer”.
        public let type: String

        /// The OpenID Connect issued by the authorization server.
        /// This token is included if the authorization server supports OpenID connect and the scope included `openid`
        public let openIDToken: String?

        /// Common Initializer.
        /// - Parameters:
        ///   - accessToken: the access token string
        ///   - refreshToken: the refresh token
        ///   - expiresIn: the expiration time in secods
        ///   - scope: the scope returned from the authorization server
        ///   - type: the token type
        ///   - openIDToken: the OpenID Connect token
        public init(accessToken: String, refreshToken: String?, expiresIn: Int?, scope: String?, type: String, openIDToken: String? = nil) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.scope = scope
            self.type = type
            self.openIDToken = openIDToken
        }

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case type = "token_type"
            case scope
            case openIDToken = "id_token"
        }
    }
}
