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

    /// Provides a structure for OAuth 2.0 Authorization Code Flow with Proof Key for Code Exchange (PKCE)
    public struct PKCE: Equatable, Sendable {

        /// A cryptographically random string using the characters A-Z, a-z, 0-9, and the punctuation characters -
        /// ._~ (hyphen, period, underscore, and tilde), between 43 and 128 characters long.
        /// See: https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
        let codeVerifier: String

        /// A transformation of the codeVerifier that is SHA-256 hashed and Base 64 URL encoded.
        /// See: https://datatracker.ietf.org/doc/html/rfc7636#section-4.2
        let codeChallenge: String

        /// The PKCE state code.
        let state: String

        /// Returns the code challenge method.
        var codeChallengeMethod: String {
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
