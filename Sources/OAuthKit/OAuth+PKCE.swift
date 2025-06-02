//
//  OAuth+PKCE.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension OAuth {

    /// Provides a structure for OAuth 2.0 Authorization Code Flow with Proof Key for Code Exchange (PKCE)
    struct PKCE {

        /// A cryptographically random string using the characters A-Z, a-z, 0-9, and the punctuation characters -
        /// ._~ (hyphen, period, underscore, and tilde), between 43 and 128 characters long.
        /// See: https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
        let codeVerifier: String
        /// A transformation of the codeVerifier that is SHA-256 hashed and Base 64 URL encoded.
        /// See: https://datatracker.ietf.org/doc/html/rfc7636#section-4.2
        let codeChallenge: String
        /// The PKCE state code
        let state: String

        /// Initializer.
        init() {
            codeVerifier = String.randomBase64URLEncoded()
            codeChallenge = codeVerifier.sha256Hash.base64URLEncoded
            state = String.randomBase64URLEncoded(count: 16)
        }
    }

}
