//
//  UtilityTests.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation
@testable import OAuthKit
import Testing

@Suite("Utility Tests", .tags(.utility))
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

        let url = URL(string: string)!
        let urlEncoded = url.absoluteString.base64URL
        #expect(encoded == urlEncoded)

        #expect(string == decoded)
    }

    /// Tests the SHA-256 hex string output.
    @Test("SHA-256 Hex")
    func whenSHA256Hex() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha256.hex
        let expectedResult = "554b0a051b6488645455eac6ddaf0978be24494bf037b1692daa9e330257ea3a"
        #expect(result == expectedResult)

        let uuid = UUID()
        let uuidHex = uuid.sha256.hex
        let expectedUUIDHex = uuid.uuidString.sha256.hex
        #expect(uuidHex == expectedUUIDHex)
    }

    /// Tests the SHA-256 Base64 string output.
    @Test("SHA-256 Base64")
    func whenSHA256Base64() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha256.base64
        let expectedResult = "VUsKBRtkiGRUVerG3a8JeL4kSUvwN7FpLaqeMwJX6jo="
        #expect(result == expectedResult)

        let url = URL(string: rawString)!
        let urlResult = url.sha256.base64
        #expect(result == urlResult)
    }

    /// Tests the SHA-256 Base64 URL string output.
    @Test("SHA-256 Base64 URL")
    func whenSHA256Base64URL() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha256.base64URL
        let expectedResult = "VUsKBRtkiGRUVerG3a8JeL4kSUvwN7FpLaqeMwJX6jo"
        #expect(result == expectedResult)
    }

    /// Tests the SHA-512 Base64 string output.
    @Test("SHA-512 Base64")
    func whenSHA512Base64() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha512.base64
        let expectedResult = "rz5qYziciQqhYSmnADG0Qzs8MfbM4qt8f5OFQ80flD87/9yYaHMEorrCYO/M6H6rM/qoWmqQ1NKN3vwIagBrmQ=="
        #expect(result == expectedResult)

        let url = URL(string: rawString)!
        let urlResult = url.sha512.base64
        #expect(result == urlResult)
    }

    /// Tests the SHA-512 Base64 URL string output.
    @Test("SHA-512 Base64URL")
    func whenSHA512Base64URL() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let result = rawString.sha512.base64URL
        let expectedResult = "rz5qYziciQqhYSmnADG0Qzs8MfbM4qt8f5OFQ80flD87_9yYaHMEorrCYO_M6H6rM_qoWmqQ1NKN3vwIagBrmQ"
        #expect(result == expectedResult)

        let url = URL(string: rawString)!
        let urlResult = url.sha512.base64URL
        #expect(result == urlResult)
    }

    /// Tests the secure random byte generation.
    @Test("Secure Random Byte Generation")
    func whenGeneratingSecureRandomData() async throws {
        var random: Data = .secureRandom()
        #expect(random.count == 32)
        random = Data.secureRandom(count: 64)
        #expect(random.count == 64)
    }

    /// Tests the encoding of data as Base 64 URL encoded.
    @Test("Data Base64 URL Encoding")
    func whenEncodingDataBase64URL() async throws {
        let rawString = "https://github.com/codefiesta/OAuthKit"
        let data: Data = rawString.data(using: .utf8)!
        let encoded: String = data.base64URLEncoded
        let expected = "aHR0cHM6Ly9naXRodWIuY29tL2NvZGVmaWVzdGEvT0F1dGhLaXQ"
        #expect(encoded == expected)
    }

    /// Tests the generation of random string generation.
    @Test("Secure Random String Generation")
    func whenGeneratingSecureRandomString() async throws {
        let random: String = .secureRandom()
        #expect(random.count >= 43)
    }

    /// Tests the scheduling of tasks
    @Test("Scheduling Tasks")
    func whenSchedulingTasks() async throws {
        let timeInterval: TimeInterval = 0
        let task: Task = .delayed(timeInterval: timeInterval) {
            return true
        }
        let executed = try await task.value
        #expect(executed)
    }
}

