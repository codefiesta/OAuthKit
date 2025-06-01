//
//  String+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension String {

    /// Calculates the SHA-256 hash of this string instance
    var sha256Hash: String {
        let hashed = SHA256.hash(data: Data(self.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Returns a Base64 encoded string.
    var base64Encoded: String {
        Data(self.utf8).base64EncodedString()
    }

    /// Returns a Base64 URL encoded string.
    /// Base64 URL encoding is a variant of Base64 encoding that is specifically designed to be safe for use in URLs and filenames.
    /// The standard Base64 characters + and / are replaced with - and _ respectively, and padding characters (=) are omitted,
    /// ensuring that the encoded data does not include any characters that have special meanings in URLs.
    var base64URLEncoded: String {
        Data(self.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Returns the decoded value of Base64 encoded string.
    var base64Decoded: String {
        guard let data = Data(base64Encoded: Data(self.utf8)) else { return self }
        return String(data: data, encoding: .utf8) ?? self
    }

    /// Returns the decoded value of Base64 URL encoded string.
    var base64URLDecoded: String {
        var result = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while result.count % 4 != 0 {
            result += "="
        }
        return result.base64Decoded
    }
}
