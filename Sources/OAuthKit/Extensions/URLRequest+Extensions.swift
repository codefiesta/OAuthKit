//
//  URLRequest+Extensions.swift
//
//
//  Created by Kevin McKee
//

import Foundation

private let authHeader = "Authorization"

public extension URLRequest {

    /// Attempts to set the authorization header using the auth token.
    /// - Parameter auth: the oauth authorization
    mutating func addAuthorization(auth: OAuth.Authorization) {
        addValue("\(auth.token.type) \(auth.token.accessToken)", forHTTPHeaderField: authHeader)
    }
}
