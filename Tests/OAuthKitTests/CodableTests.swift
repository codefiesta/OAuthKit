//
//  CodeableTests.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation
@testable import OAuthKit
import Testing

@Suite("Codable Tests")
struct CodableTests {

    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = .init()

    @Test("Encoding and Decoding Tokens")
    func whenEncodingDecodingTokens() async throws {

        let token: OAuth.Token = .init(accessToken: UUID().uuidString, refreshToken: UUID().uuidString, expiresIn: 3600, state: "xyz", type: "bearer")

        let data = try encoder.encode(token)
        let decoded: OAuth.Token = try decoder.decode(OAuth.Token.self, from: data)
        #expect(token == decoded)
    }

}
