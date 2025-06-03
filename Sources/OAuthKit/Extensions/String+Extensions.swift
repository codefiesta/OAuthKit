//
//  String+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension String {

    /// Denotes an empty string.
    static let empty = ""

    /// Returns the SHA-256 Digest for this string instance
    var sha256: SHA256.Digest {
        Data(self.utf8).sha256
    }

    /// Returns the SHA-512 Digest for this string instance
    var sha512: SHA512.Digest {
        Data(self.utf8).sha512
    }

    /// Encodes the string as a Base64 encoded string.
    var base64: String {
        Data(self.utf8).base64EncodedString()
    }

    /// Encodes the string as a Base64 URL encoded string.
    /// Base64 URL encoding is a variant of Base64 encoding that is specifically designed to be safe for use in URLs and filenames.
    ///
    /// Key Differences Between Base64 and Base64 URL Encoding:
    /// 1. **Character Set**
    ///     * `Base64`: Uses `+` and `/`
    ///     * `Base64URL`: Uses `-` and `_`
    /// 2. **Padding**
    ///     * `Base64`: May include `=` padding to ensure the encoded string length is a multiple of 4.
    ///     * `Base64URL`: Omits padding characters.
    var base64URL: String {
        base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Returns the decoded value of this Base64 encoded string.
    var base64Decoded: String {
        guard let data = Data(base64Encoded: Data(self.utf8)) else { return self }
        return String(data: data, encoding: .utf8) ?? self
    }

    /// Returns the decoded value of this Base64 URL encoded string.
    var base64URLDecoded: String {
        var result = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while result.count % 4 != 0 {
            result += "="
        }
        return result.base64Decoded
    }

    /// Generates a cryptographically secure random Base 64 URL encoded string.
    /// - Parameter count: the byte count
    /// - Returns: a cryptographically secure random Base 64 URL encoded string
    static func secureRandom(count: Int = 32) -> String {
        let data: Data = .secureRandom(count: count)
        return data.sha256.base64URL
    }
}
