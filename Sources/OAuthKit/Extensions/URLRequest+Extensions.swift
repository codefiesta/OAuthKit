//
//  URLRequest+Extensions.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Foundation

private let bearer = "Bearer"
private let authHeader = "Authorization"

public extension URLRequest {

    /// Attempts to set the authorization header using the access token.
    /// - Parameter oath: the oauth holder
    @MainActor
    mutating func addAuthorization(oath: OAuth) {
        switch oath.state {
        case .authorized(let auth):
            addValue("\(bearer) \(auth.token.accessToken)", forHTTPHeaderField: authHeader)
        case .empty, .authorizing, .requestingAccessToken:
            debugPrint("⚠️ [OAuth is not authorized]")
        }
    }
}
