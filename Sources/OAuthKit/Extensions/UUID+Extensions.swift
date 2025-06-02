//
//  UUID+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import CryptoKit
import Foundation

extension UUID {

    /// Returns the SHA-256 Digest for this UUID.
    var sha256: SHA256.Digest {
        uuidString.sha256
    }
}
