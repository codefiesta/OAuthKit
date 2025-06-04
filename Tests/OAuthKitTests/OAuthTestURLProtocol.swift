//
//  OAauthTestURLProtocol.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation
@testable import OAuthKit

/// The version of the http response
private let httpVersion = "HTTP/1.1"

/// Builds and responds to mock test requests.
private actor OAuthTestRequestHandler {

    /// Returns an URL response for the given request and status code
    /// - Parameters:
    ///   - request: the request
    ///   - statusCode: the status code to return
    /// - Returns: an url response
    private func response(request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: httpVersion, headerFields: nil)!
    }

    /// Returns data for the given request.
    /// - Parameter request: the request
    /// - Returns: the data to respond with
    private func data(request: URLRequest) -> Data {
        guard let url = request.url else {
            return .init()
        }

        // Returns oauth access token data
        if url.absoluteString.contains("token") {
            let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: nil, expiresIn: 3600, scope: nil, type: "Bearer")
            return try! JSONEncoder().encode(token)
        }

        // Returns device code data
        if url.absoluteString.contains("device") {
            let deviceCode: OAuth.DeviceCode = .init(deviceCode: .secureRandom(), userCode: "0A17-B332", verificationUri: "https://github.com/codefiesta/OAuthKit", expiresIn: 2, interval: 1)
            return try! JSONEncoder().encode(deviceCode)
        }

        return .init()
    }

    /// Returns a mocked test response for the given url request
    /// - Parameter request: the url request to return a mock test response for
    /// - Returns: a tuple of response and data
    func execute(_ request: URLRequest) async throws -> (HTTPURLResponse, Data) {
        let response = response(request: request)
        let data = data(request: request)
        return (response, data)
    }
}

/// OAuth Test URL Protocol that intercepts test request and returns mocked response data
class OAuthTestURLProtocol: URLProtocol, @unchecked Sendable {

    /// The handler responsible for returning mocked test response data
    private static let handler: OAuthTestRequestHandler = .init()

    /// Determines whether this protocol can handle the given request.
    /// - Parameter request: the request to handle
    /// - Returns: always true
    override class func canInit(with request: URLRequest) -> Bool { true }

    /// Returns the canonical version of the given request.
    /// - Parameter request: the request
    /// - Returns: the canonical version of the given request.
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// Starts loading the given request.
    override func startLoading() {
        Task {
            do {
                let (response, data) = try await Self.handler.execute(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    /// Stops the loading of a request.
    override func stopLoading() {}

}
