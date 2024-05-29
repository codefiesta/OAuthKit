//
//  EnvironmentValues+Extensions.swift
//
//
//  Created by Kevin McKee on 5/16/24.
//

import SwiftUI

public extension EnvironmentValues {

    /// Exposes `@Environment(\.oauth) var oauth` to Views.
    var oauth: OAuth {
        get { self[OAuthKey.self] }
        set { self[OAuthKey.self] = newValue }
    }
}

private struct OAuthKey: EnvironmentKey {
    static var defaultValue: OAuth = .init(.main)
}
