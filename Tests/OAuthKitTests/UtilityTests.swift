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
        let encoded = string.base64
        let decoded = encoded.base64Decoded
        #expect(string == decoded)
    }

    /// Tests the Base64 URL encoding.
    @Test("Base64 URL Encoding and Decoding")
    func whenBase64URLEncoding() async throws {
        let string = "https://github.com/codefiesta/OAuthKit"
        let encoded = string.base64URL
        let decoded = encoded.base64URLDecoded
        #expect(string == decoded)
    }

    /// Tests the SHA256 hex string output.
    @Test("SHA-256 Hex")
    func whenSHA256Hex() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha256.hex
        let expectedResult = "554b0a051b6488645455eac6ddaf0978be24494bf037b1692daa9e330257ea3a"
        #expect(result == expectedResult)
    }

    /// Tests the SHA256 Base64 string output.
    @Test("SHA-256 Base64")
    func whenSHA256Base64() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha256.base64
        let expectedResult = "VUsKBRtkiGRUVerG3a8JeL4kSUvwN7FpLaqeMwJX6jo="
        #expect(result == expectedResult)
    }

    /// Tests the SHA256 Base64 URL string output.
    @Test("SHA-256 Base64 URL")
    func whenSHA256Base64URL() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha256.base64URL
        let expectedResult = "VUsKBRtkiGRUVerG3a8JeL4kSUvwN7FpLaqeMwJX6jo"
        #expect(result == expectedResult)
    }

    /// Tests the secure random byte generation.
    @Test("Secure Random Byte Generation")
    func whenGeneratingSecureRandomData() async throws {
        var random: Data = .secureRandom()
        #expect(random.count == 32)
        random = Data.secureRandom(count: 64)
        #expect(random.count == 64)
    }

    /// Tests the generation of random Base64 URL generation.
    @Test("Secure Random String Generation")
    func whenGeneratingSecureRandomString() async throws {
        let random: String = .secureRandom()
        debugPrint("✅", random)
        #expect(random.count >= 43)
    }
}

