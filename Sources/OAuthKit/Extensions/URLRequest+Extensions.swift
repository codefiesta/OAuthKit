//
//  URLRequest+Extensions.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Foundation

private let authHeader = "Authorization"

public extension URLRequest {

    /// Attempts to set the authorization header using the auth token.
    /// - Parameter oath: the oauth authorization
    @MainActor
    mutating func addAuthorization(authorization: OAuth.Authorization) {
        addValue("\(authorization.token.type) \(authorization.token.accessToken)", forHTTPHeaderField: authHeader)
    }
}
