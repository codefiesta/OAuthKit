//
//  OAuthTestLAContext.swift
//  OAuthKit
//
//  Created by Kevin McKee
//
#if !os(tvOS)
import Foundation
import LocalAuthentication

/// Provides an LAContext that can be safely used in tests that have set `.requireAuthenticationWithBiometricsOrCompanion` to true.
class OAuthTestLAContext: LAContext {

    var canEvaluatePolicy: Bool = true
    var evaluatePolicyError: Error?

    /// Returns the localized reason for biometric or companion device authentication.
    override var localizedReason: String  {
        set { }
        get {
            return "test keychain access"
        }
    }

    /// Overrides the evaluate policy to always succeed.
    /// - Parameters:
    ///   - policy: the policy to evaludate
    ///   - localizedReason: the reason for access
    ///   - reply: the evaluation reply.
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String?, reply: @escaping (Bool, Error?) -> Void) {
        reply(true, nil)
    }
}
#endif
