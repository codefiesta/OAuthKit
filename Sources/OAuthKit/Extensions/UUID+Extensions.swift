//
//  UUID+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension UUID {

    /// Calculates the SHA-256 hash of for this UUID.
    var sha256Hash: String {
        uuidString.sha256Hash
    }
}
