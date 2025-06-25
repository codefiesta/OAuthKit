//
//  Data+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension Data {

    /// Returns the SHA-256 Digest of this data block.
    var sha256: SHA256.Digest {
        SHA256.hash(data: self)
    }

    /// Returns the SHA-512 Digest of this data block.
    var sha512: SHA512.Digest {
        SHA512.hash(data: self)
    }

    /// Encodes the data as a Base64 URL encoded string.
    /// Base64 URL encoding is a variant of Base64 encoding that is specifically designed to be safe for use in URLs and filenames.
    ///
    /// Key Differences Between Base64 and Base64 URL Encoding:
    /// 1. **Character Set**
    ///     * `Base64`: Uses `+` and `/`
    ///     * `Base64URL`: Uses `-` and `_`
    /// 2. **Padding**
    ///     * `Base64`: May include `=` padding to ensure the encoded string length is a multiple of 4.
    ///     * `Base64URL`: Omits padding characters.
    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Generates secure random bytes for the specified byte counts.
    /// - Parameter count: The number of bytes to generate.
    /// - Returns: an array of cryptographically secure random bytes
    static func secureRandom(count: Int = 32) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes: &bytes, count: bytes.count)
    }
}
