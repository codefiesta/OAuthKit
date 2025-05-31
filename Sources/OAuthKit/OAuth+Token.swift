//
//  OAuth+Token.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// A codable type that holds oauth token information.
    /// See: https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-5.1
    public struct Token: Codable, Equatable, Sendable {

        public let accessToken: String
        public let refreshToken: String?
        public let expiresIn: Int?
        public let state: String?
        public let type: String

        public init(accessToken: String, refreshToken: String?, expiresIn: Int?, state: String?, type: String) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.state = state
            self.type = type
        }

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case type = "token_type"
            case state
        }
    }

}
