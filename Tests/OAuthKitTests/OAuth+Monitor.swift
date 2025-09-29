//
//  OAuth+Monitor.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation
@testable import OAuthKit

extension OAuth {

    /// Provides a testing utility to stream an oauth state until it's received an authorization.
    /// This is necessary because a unit test can potentially die as an asynchronous request is received that
    /// inserts an authorization record into the keychain. This allows us to keep the keychain clean and not get littered with test records.
    @MainActor
    class Monitor {

        typealias OAuthStateAsyncStream = AsyncStream<OAuth.State>

        private let oauth: OAuth

        var continuation: OAuthStateAsyncStream.Continuation?

        lazy var stream: OAuthStateAsyncStream = {
            AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
                self.continuation = continuation
                waitForNextValue()
            }
        }()

        /// Initialzation.
        /// - Parameter oauth: the oauth state to stream
        init(oauth: OAuth) {
            self.oauth = oauth
        }

        deinit {
            continuation?.finish()
        }

        /// Waits for the next state value to be received. This will continue until we've received an `.authorized` state.
        private func waitForNextValue() {
            Task {
                let state = oauth.state
                continuation?.yield(state)
                switch state {
                case .empty, .error, .authorizing, .requestingAccessToken, .requestingDeviceCode, .receivedDeviceCode:
                    waitForNextValue()
                case .authorized(_, _):
                    continuation?.finish()
                }
            }
        }
    }
}
