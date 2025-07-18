//
//  OAuth+PKCE.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

/// The default code challenge method (SHA-256 hash).
private let defaultCodeChallengeMethod = "S256"

extension OAuth {

    /// Provides a structure for OAuth 2.0 Authorization Code Flow with Proof Key for Code Exchange (PKCE).
    public struct PKCE: Equatable, Sendable {

        /// A cryptographically random string between 43 and 128 characters long.
        /// See RFC 7636 Standard  [PKCE Code Verifier](https://datatracker.ietf.org/doc/html/rfc7636#section-4.1).
        public let codeVerifier: String

        /// A code challenge derived from the codeVerifier that is a Base 64 URL encoded string from it's SHA-256 digest.
        /// See RFC 7636 Standard  [PKCE Code Challenge](https://datatracker.ietf.org/doc/html/rfc7636#section-4.2).
        public let codeChallenge: String

        /// The PKCE state code.
        public let state: String

        /// Returns the code challenge method. Currently only supports [SHA-256 hash](https://en.wikipedia.org/wiki/SHA-2).
        public var codeChallengeMethod: String {
            defaultCodeChallengeMethod
        }

        /// Initializer.
        public init() {
            codeVerifier = .secureRandom()
            codeChallenge = codeVerifier.sha256.base64URL
            state = .secureRandom(count: 16).base64URL
        }
    }
}
