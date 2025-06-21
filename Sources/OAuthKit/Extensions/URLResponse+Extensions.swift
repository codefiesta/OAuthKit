//
//  URLResponse+Extensions.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

public extension URLResponse {

    /// Returns true if the response status code is in the 200's.
    var isOK: Bool {
        guard let code = statusCode() else { return false }
        return 200...299 ~= code
    }

    /// Extracts the status code from the response.
    func statusCode() -> Int? {
        guard let httpResponse = self as? HTTPURLResponse else { return nil }
        return httpResponse.statusCode
    }
}

