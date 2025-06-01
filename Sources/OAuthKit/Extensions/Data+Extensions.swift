//
//  Data+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension Data {

    /// Calculates the SHA-256 hash of for this data block.
    var sha256Hash: String {
        let hashed = SHA256.hash(data: self)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
