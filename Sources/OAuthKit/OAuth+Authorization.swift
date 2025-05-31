//
//  OAuth+Authorization.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// A codable type that holds authorization information that can be stored.
    public struct Authorization: Codable, Equatable, Sendable {

        /// The provider ID that issued the authorization.
        public let issuer: String
        /// The issue date.
        public let issued: Date
        /// The issued access token.
        public let token: Token

        /// Initializer
        /// - Parameters:
        ///   - issuer: the provider ID that issued the authorization.
        ///   - token: the access token
        ///   - issued: the issued date
        public init(issuer: String, token: Token, issued: Date = Date.now) {
            self.issuer = issuer
            self.token = token
            self.issued = issued
        }

        /// Returns true if the token is expired.
        public var isExpired: Bool {
            guard let expiresIn = token.expiresIn else { return false }
            return issued.addingTimeInterval(Double(expiresIn)) < Date.now
        }

        /// Returns the expiration date of the authorization or nil if none exists.
        public var expiration: Date? {
            guard let expiresIn = token.expiresIn else { return nil }
            return issued.addingTimeInterval(TimeInterval(expiresIn))
        }
    }

}
