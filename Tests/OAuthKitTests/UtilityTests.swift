//
//  UtilityTests.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation
@testable import OAuthKit
import Testing

@Suite("Utility Tests")
struct UtilityTests {

    /// Tests the Base64 encoding.
    @Test("Base64 Encoding and Decoding")
    func whenBase64Encoding() async throws {
        let string = "https://github.com/codefiesta/OAuthKit"
        let encoded = string.base64Encoded
        let decoded = encoded.base64Decoded
        #expect(string == decoded)
    }

    /// Tests the Base64 URL encoding.
    @Test("Base64 URL Encoding and Decoding")
    func whenBase64URLEncoding() async throws {
        let string = "https://github.com/codefiesta/OAuthKit"
        let encoded = string.base64URLEncoded
        let decoded = encoded.base64URLDecoded
        #expect(string == decoded)
    }

    /// Tests the SHA256 hashing.
    @Test("SHA-256 Hashing")
    func whenSHA256Hashing() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let expectedResult = "554b0a051b6488645455eac6ddaf0978be24494bf037b1692daa9e330257ea3a"
        let sha256Hash = rawString.sha256Hash
        #expect(sha256Hash == expectedResult)
    }

    /// Tests the random byte generation.
    @Test("Random Byte Generation")
    func whenGeneratingRandomBytes() async throws {
        var random = Data.random()
        #expect(random.count == 32)
        random = Data.random(count: 64)
        #expect(random.count == 64)
    }

    /// Tests the generation of random Base64 URL generation.
    @Test("Random Base64 URL String Generation")
    func whenGeneratingRandomBase64URL() async throws {
        let random = String.randomBase64URLEncoded()
        #expect(random.count >= 43)
    }
}

