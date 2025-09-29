//
//  EnvironmentValues+Extensions.swift
//
//
//  Created by Kevin McKee
//

import SwiftUI

public extension EnvironmentValues {

    /// Exposes `@Environment(\.oauth) var oauth` to Views.
    var oauth: OAuth {
        get { self[OAuthKey.self] }
        set { self[OAuthKey.self] = newValue }
    }
}

struct OAuthKey: @preconcurrency EnvironmentKey {

    /// The default OAuth instance that is loaded into the environment.
    @MainActor static let defaultValue: OAuth = .init(.main)
}
