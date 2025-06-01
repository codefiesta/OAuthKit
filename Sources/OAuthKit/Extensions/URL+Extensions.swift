//
//  URL+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension URL {

    /// Calculates the SHA-256 hash of an url
    var sha256Hash: String {
        let hashed = SHA256.hash(data: Data(self.absoluteString.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Returns a Base64 encoded string representation for this URL
    var base64Encoded: String {
        absoluteString.base64Encoded
    }

    /// Returns a Base64 URL encoded string representation for this URL.
    var base64URLEncoded: String {
        absoluteString.base64URLEncoded
    }
}
