//
//  Digest+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension Digest {

    /// Returns the digest as a byte array.
    var bytes: [UInt8] {
        Array(makeIterator())
    }

    /// Returns the digest as data
    var data: Data {
        Data(bytes)
    }

    /// Returns the digest hex string value.
    var hex: String {
        bytes.map { String(format: "%02X", $0) }.joined().lowercased()
    }

    /// Returns the digest base64 encoded string value.
    var base64: String {
        data.base64EncodedString()
    }

    /// Returns the digest base64 URL encoded string value.
    var base64URL: String {
        base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
