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

private let statusCodeSuccess = 200
private let statusCodeBadRequest = 400
private let statusCodeServerError = 500

/// Builds and responds to mock test requests.
actor OAuthTestRequestHandler {

    let encoder: JSONEncoder = .init()
    let statusCode: Int

    /// Initializr
    /// - Parameter statusCode: the status code to return
    init(statusCode: Int = statusCodeSuccess) {
        self.statusCode = statusCode
    }

    /// Returns a mocked URL response for the given request and status code
    /// - Parameters:
    ///   - request: the request
    ///   - statusCode: the status code to return
    /// - Returns: an url response
    private func response(request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: httpVersion, headerFields: nil)!
    }

    /// Returns mock test data for the given request.
    /// - Parameter request: the request
    /// - Returns: the data to respond with
    private func data(request: URLRequest) -> Data {

        guard statusCode == statusCodeSuccess, let url = request.url else { return .init() }

        // Returns device code data
        if url.absoluteString.contains("grant_type=device_code") {
            let deviceCode: OAuth.DeviceCode = .init(deviceCode: .secureRandom(), userCode: "0A17-B332", verificationUri: "https://github.com/codefiesta/OAuthKit", expiresIn: 2, interval: 1)
            return try! encoder.encode(deviceCode)
        }

        // Returns oauth access token data
        if url.absoluteString.contains("token") {
            let token: OAuth.Token = .init(accessToken: .secureRandom(), refreshToken: .secureRandom(), expiresIn: 3600, scope: nil, type: "Bearer")
            return try! encoder.encode(token)
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

/// OAuth Test URL Protocol that intercepts test request and returns mocked response data.
class OAuthTestURLProtocol: URLProtocol, @unchecked Sendable {

    /// The handler responsible for returning mocked test response data
    var handler: OAuthTestRequestHandler {
        .init()
    }

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
            // Client error
            guard handler.statusCode != 500 else {
                client?.urlProtocol(self, didFailWithError: OAError.badResponse)
                return
            }
            do {
                let (response, data) = try await handler.execute(request)
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

class OAuthTestClientErrorURLProtocol: OAuthTestURLProtocol, @unchecked Sendable {

    override var handler: OAuthTestRequestHandler {
        .init(statusCode: statusCodeBadRequest)
    }
}

class OAuthTestServerErrorURLProtocol: OAuthTestURLProtocol, @unchecked Sendable {

    override var handler: OAuthTestRequestHandler {
        .init(statusCode: statusCodeServerError)
    }
}
