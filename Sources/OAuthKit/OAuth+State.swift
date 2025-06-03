//
//  OAuth+State.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// Holds the OAuth state that is published to subscribers via the `OAuth.state` property publisher.
    public enum State: Equatable, Sendable {

        /// The state is empty and no authorizations or tokens have been issued.
        case empty

        /// The OAuth authorization workflow has been started for the specifed provider and grant type.
        /// - Parameters:
        ///   - Provider: the oauth provider
        ///   - GrantType: the grant type
        case authorizing(Provider, GrantType)

        /// An access token is being requested for the specifed provider.
        /// - Parameters:
        ///   - Provider: the oauth provider
        case requestingAccessToken(Provider)

        /// A device code is being requested for the specifed provider.
        /// - Parameters:
        ///   - Provider: the oauth provider
        case requestingDeviceCode(Provider)

        /// A device code has been received by the specified provider and it's access token endpoint is
        /// actively being polled at the device code's interval until it expires, or until an error or access token is returned.
        /// - Parameters:
        ///   - Provider: the oauth provider
        ///   - DeviceCode: the device code
        case receivedDeviceCode(Provider, DeviceCode)

        /// An authorization has been granted.
        /// - Parameters:
        ///   - Provider: the oauth provider
        ///   - Authorization: the oauth authorization
        case authorized(Provider, Authorization)
    }
}
