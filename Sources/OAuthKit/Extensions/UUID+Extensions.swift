//
//  UUID+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import Foundation

extension UUID {

    /// Returns the SHA-256 Digest for this UUID.
    var sha256: SHA256.Digest {
        uuidString.sha256
    }
}
