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
        if let code = statusCode()  {
            return 200...299 ~= code
        }
        return false
    }

    /// Extracts the status code from the response.
    func statusCode() -> Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return nil
    }
}

