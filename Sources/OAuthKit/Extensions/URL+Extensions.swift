//
//  URL+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension URL {

    /// Returns the SHA-256 Digest for this URL.
    var sha256: SHA256.Digest {
        absoluteString.sha256
    }

    /// Returns the SHA-256 Digest for this URL.
    var sha512: SHA512.Digest {
        absoluteString.sha512
    }

    /// Returns a Base64 encoded string representation for this URL
    var base64Encoded: String {
        absoluteString.base64
    }

    /// Returns a Base64 URL encoded string representation for this URL.
    var base64URLEncoded: String {
        absoluteString.base64URL
    }
}
