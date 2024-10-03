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

struct OAuthKey: EnvironmentKey {

    /// The default OAuth instance that is loaded into the environment.
    static let defaultValue: OAuth = .init(.main)
}
