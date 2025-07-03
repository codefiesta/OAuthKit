//
//  OAuth.swift
//
//
//  Created by Kevin McKee on 5/14/24.
//
import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
import Observation

/// The default file name that holds the list of providers.
private let defaultResourceName = "oauth"
/// The default file extension.
private let defaultExtension = "json"
/// The default reason for local authentication with biometrics or companion device.
private let defaultAuthenticationWithBiometricsOrCompanionReason = "unlock keychain"

/// Provides an enum of oauth errors.
public enum OAError: Error {
    /// An error occurred while building a request url
    case malformedURL
    /// An error occurred while loading data from a request
    case badResponse
    /// Unable to decode a response from a provider into an expected type.
    case decoding
    /// Unable to write data to the keychain
    case keychain
}

/// Provides an `Observable` OAuth 2.0 implementation that emits ``OAuth/state`` changes when
/// an authorization flow is started by calling ``OAuth/authorize(provider:grantType:)``.
///
/// You can create an observable OAuth object using the ``OAuth/init(_:options:)`` or ``OAuth/init(providers:options:)`` initializers, or
/// you can access a default OAuth object via SwiftUI ``SwiftUICore/EnvironmentValues`` via the following:
///
/// ```swift
/// @Environment(\.oauth)
/// var oauth: OAuth
/// ```
///
/// An OAuth object can also be highly customized when passed a dictionary  of  ``Option`` values into it's iniitializers.
/// ```swift
/// let options: [OAuth.Option: Any] = [
///     .applicationTag: "com.bundle.Idenfitier",
///     .autoRefresh: true,
///     .requireAuthenticationWithBiometricsOrCompanion: true,
///     .useNonPersistentWebDataStore: true
/// ]
/// let oauth: OAuth = .init(.module, options: options)
/// ```
///
/// - SeeAlso:
/// [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
@MainActor
@Observable
public final class OAuth {

    /// An observable list of available OAuth providers to choose from.
    public var providers = [Provider]()

    /// An observable oauth state.
    public var state: State = .empty

    /// The url session to use for communicating with providers.
    @ObservationIgnored
    public var urlSession: URLSession = .init(configuration: .ephemeral)

    @ObservationIgnored
    var keychain: Keychain = .default

    #if os(macOS) || os(iOS) || os(visionOS)
    @ObservationIgnored
    var context: LAContext = .init()
    #endif

    @ObservationIgnored
    private var tasks = [Task<(), any Error>]()

    @ObservationIgnored
    private let networkMonitor = NetworkMonitor()

    /// Configuration option determining if tokens should be auto refreshed or not.
    @ObservationIgnored
    private var autoRefresh: Bool = false

    /// Configuration option determining if the WKWebsiteDataStore used during authorization flows should use an ephemeral datastore.
    /// Set to true if you wish to implement private browsing and force a new login attempt every time an authorization flow is started.
    @ObservationIgnored
    var useNonPersistentWebDataStore: Bool = false

    /// Configuration option determining if the keychain should be protected with biometrics until sucessful local authentication.
    /// If set to true, the device owner will need to be authenticated by biometry or a companion device before the keychain items can be accessed.
    @ObservationIgnored
    var requireAuthenticationWithBiometricsOrCompanion: Bool = false

    /// The json decoder
    @ObservationIgnored
    private let decoder: JSONDecoder = .init()

    /// Initializes the OAuth service with the specified providers and configuration options.
    /// - Parameters:
    ///   - providers: the list of oauth providers
    ///   - options: the configuration options to apply
    public init(providers: [Provider] = [Provider](), options: [Option: Any]? = nil) {
        self.providers = providers
        configure(options)
    }

    /// Common Initializer that attempts to load an `oauth.json` file from the specified bundle.
    /// - Parameters:
    ///   - bundle: the bundle to load the oauth provider configuration information from.
    ///   - options: the configuration options to apply
    public init(_ bundle: Bundle, options: [Option: Any]? = nil) {
        self.providers = loadProviders(bundle)
        configure(options)
    }
}

public extension OAuth {

    /// Generates a cryptographically secure random Base 64 URL encoded string.
    /// - Parameter count: the byte count
    /// - Returns: a cryptographically secure random Base 64 URL encoded string
    static func secureRandom(count: Int = 32) -> String {
        .secureRandom(count: count)
    }

    /// Starts the authorization process for the specified provider.
    /// - Parameters:
    ///   - provider: the provider to begin authorization for
    ///   - grantType: the grant type to execute
    func authorize(provider: Provider, grantType: GrantType = .pkce(.init())) {
        switch grantType {
        case .authorizationCode:
            state = .authorizing(provider, grantType)
        case .pkce:
            state = .authorizing(provider, grantType)
        case .deviceCode:
            state = .requestingDeviceCode(provider)
            Task(priority: .high) {
                await requestDeviceCode(provider: provider)
            }
        case .clientCredentials:
            Task(priority: .high) {
                await requestClientCredentials(provider: provider)
            }
        case .refreshToken:
            Task(priority: .high) {
                await refreshToken(provider: provider)
            }
        }
    }

    /// Requests to exchange a code for an access token.
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
    /// - Parameters:
    ///   - provider: the provider the access token is being requested from
    ///   - code: the code to exchange
    ///   - pkce: the pkce data
    func token(provider: Provider, code: String, pkce: PKCE? = nil) {
        Task(priority: .high) {
            let result = await requestToken(provider: provider, code: code, pkce: pkce)
            switch result {
            case .success(let token):
                if provider.debug {
                    debugPrint("➡️ [Received token], [\(token)]")
                }
            case .failure(let error):
                if provider.debug {
                    debugPrint("➡️ [Error requesting access token], [\(error)]")
                }
            }
        }
    }

    /// Removes all tokens and clears the OAuth state
    func clear() {
        debugPrint("⚠️ [Clearing oauth state]")
        keychain.clear()
        state = .empty
    }
}

// MARK: Private

private extension OAuth {

    /// Loads providers from the specified bundle.
    /// - Parameter bundle: the bundle to load the oauth provider configuration information from.
    /// - Returns: found providers in the specifed bundle or an empty list if not found
    func loadProviders(_ bundle: Bundle) -> [Provider] {
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: defaultExtension),
              let data = try? Data(contentsOf: url),
              let providers = try? decoder.decode([Provider].self, from: data) else {
            return []
        }
        return providers
    }

    /// Loads authorizations from the keychain.
    func loadAuthorizations() {
        for provider in providers {
            if let authorization: OAuth.Authorization = try? keychain.get(key: provider.id) {
                publish(state: .authorized(provider, authorization))
            }
        }
    }

    /// Configures the oauth client from options.
    /// - Parameter options: the options to apply to this oauth client
    func configure(_ options: [Option: Any]?) {
        // Override from options
        if let options {

            // Override token auto refresh
            if let autoRefresh = options[.autoRefresh] as? Bool {
                self.autoRefresh = autoRefresh
            }

            // Ephemeral web data store
            if let useNonPersistentWebDataStore = options[.useNonPersistentWebDataStore] as? Bool {
                self.useNonPersistentWebDataStore = useNonPersistentWebDataStore
            }

            // Keychain protection with biometrics or companion device
            if let requireAuthenticationWithBiometricsOrCompanion = options[.requireAuthenticationWithBiometricsOrCompanion] as? Bool {
                self.requireAuthenticationWithBiometricsOrCompanion = requireAuthenticationWithBiometricsOrCompanion
            }

            // Override the local authentication context
            #if os(macOS) || os(iOS) || os(visionOS)
            if let context = options[.localAuthentication] as? LAContext {
                self.context = context
            }
            #endif

            // Override the url session
            if let urlSession = options[.urlSession] as? URLSession {
                self.urlSession = urlSession
            }

            // Override the keychain to use the custom application tag
            if let applicationTag = options[.applicationTag] as? String, applicationTag.isNotEmpty {
                self.keychain = .init(applicationTag)
            }
        }
        monitor()
        restore()
    }

    /// Restores state from storage. If the keychain is protected by biometrics with local authentication, then
    /// the device owner needs to authenticate with biometrics or companion app before any tokens in the keychain can be accessed.
    func restore() {
        if requireAuthenticationWithBiometricsOrCompanion {
            authenticateWithBiometricsOrCompanion()
        } else {
            loadAuthorizations()
        }
    }

    /// Device owner will be authenticated by biometry or a companion device e.g. watch, mac, etc.
    func authenticateWithBiometricsOrCompanion() {

        #if os(macOS) || os(iOS) || os(visionOS)
        let localizedReason = context.localizedReason.isNotEmpty ? context.localizedReason: defaultAuthenticationWithBiometricsOrCompanionReason
        #if os(macOS) || os(iOS)
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometricsOrCompanion
        #else
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        #endif
        var error: NSError?
        if context.canEvaluatePolicy(policy, error: &error) {
            context.evaluatePolicy(policy, localizedReason: localizedReason) { [weak self] success, error in
                guard let self else { return }
                Task(priority: .high) { @MainActor in
                    if success {
                        self.loadAuthorizations()
                    }
                }
            }
        }
        #else
        debugPrint("⚠️ Misconfigured option: `requireAuthenticationWithBiometricsOrCompanion` is set to true but the current platform does not support biometric authentication.")
        loadAuthorizations()
        #endif
    }

    /// Starts the network monitor.
    func monitor() {
        Task {
            await networkMonitor.start()
        }
    }

    /// Publishes state on the main thread.
    /// - Parameter state: the new state information to publish out on the main thread.
    func publish(state: State) {
        switch state {
        case .authorized(let provider, let auth):
            schedule(provider: provider, auth: auth)
        case .receivedDeviceCode(let provider, let deviceCode):
            schedule(provider: provider, deviceCode: deviceCode)
        case .empty, .authorizing, .requestingAccessToken, .requestingDeviceCode:
            break
        }
        self.state = state
    }

    /// Schedules the provider to be polled for authorization with the specified device token.
    /// - Parameters:
    ///   - provider: the oauth provider
    ///   - deviceCode: the device code issued by the provider
    func schedule(provider: Provider, deviceCode: DeviceCode) {
        let timeInterval: TimeInterval = .init(deviceCode.interval)
        let task = Task.delayed(timeInterval: timeInterval) { [weak self] in
            guard let self else { return }
            await self.poll(provider: provider, deviceCode: deviceCode)
        }
        tasks.append(task)
    }

    /// Schedules refresh tasks for the specified authorization.
    /// - Parameters:
    ///   - provider: the oauth provider
    ///   - auth: the authentication to schedule a future tasks for
    func schedule(provider: Provider, auth: Authorization) {
        // Don't bother scheduling a task for tokens that can't refresh
        guard let _ = auth.token.refreshToken else { return }

        if autoRefresh {
            if let expiration = auth.expiration {
                let timeInterval = expiration - Date.now
                if timeInterval > 0 {
                    // Schedule the auto refresh task
                    let task = Task.delayed(timeInterval: timeInterval) { [weak self] in
                        guard let self else { return }
                        await self.refreshToken(provider: provider)
                    }
                    tasks.append(task)
                } else {
                    // Execute the task immediately
                    Task(priority: .high) {
                        await refreshToken(provider: provider)
                    }
                }
            }
        }
    }
}

// MARK: URLRequests

extension OAuth {

    /// Requests to exchange a code for an access token.
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
    /// - Parameters:
    ///   - provider: the provider the access token is being requested from
    ///   - code: the code to exchange
    ///   - pkce: the PKCE data to pass along with the request
    /// - Returns: the exchange result
    @discardableResult
    func requestToken(provider: Provider, code: String, pkce: PKCE? = nil) async -> Result<Token, OAError> {
        // Publish the state
        publish(state: .requestingAccessToken(provider))

        guard let request = Request.token(provider: provider, code: code, pkce: pkce) else {
            publish(state: .empty)
            return .failure(.malformedURL)
        }

        guard let (data, response) = try? await urlSession.data(for: request) else {
            publish(state: .empty)
            return .failure(.badResponse)
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        // Decode the token
        guard let token = try? decoder.decode(Token.self, from: data) else {
            publish(state: .empty)
            return .failure(.decoding)
        }

        // Store the authorization
        let authorization = Authorization(issuer: provider.id, token: token)
        guard let stored = try? keychain.set(authorization, for: authorization.issuer), stored else {
            publish(state: .empty)
            return .failure(.keychain)
        }

        publish(state: .authorized(provider, authorization))
        return .success(token)
    }

    /// Refreshes the token for the specified provider.
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-6
    /// - Parameters:
    ///   - provider: the provider to request a refresh token for
    func refreshToken(provider: Provider) async {
        guard let auth: OAuth.Authorization = try? keychain.get(key: provider.id) else { return }

        // If we can't build a refresh request simply bail as no refresh token
        // was returned in the original auth request
        guard let request = Request.refresh(provider: provider, token: auth.token) else {
            if auth.isExpired { clear() }
            return
        }

        guard let (data, response) = try? await urlSession.data(for: request) else {
            return publish(state: .empty)
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        // Decode the token
        guard response.isOK, let token = try? decoder.decode(Token.self, from: data) else {
            return publish(state: .empty)
        }

        // Store the authorization
        let authorization = Authorization(issuer: provider.id, token: token)
        guard let stored = try? keychain.set(authorization, for: authorization.issuer), stored else {
            return publish(state: .empty)
        }
        publish(state: .authorized(provider, authorization))
    }

    /// Requests a device code from the specified provider.
    /// - Parameters:
    ///   - provider: the provider the device code is being requested from
    func requestDeviceCode(provider: Provider) async {
        guard let request = Request.device(provider: provider) else { return }
        guard let (data, response) = try? await urlSession.data(for: request) else {
            return publish(state: .empty)
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        // Decode the device code
        guard let deviceCode = try? decoder.decode(DeviceCode.self, from: data) else {
            return publish(state: .empty)
        }

        // Publish the state
        publish(state: .receivedDeviceCode(provider, deviceCode))
    }

    /// Makes a client credentials request grant request from the specified provider.
    /// - Parameters:
    ///   - provider: the provider the device code is being requested from
    func requestClientCredentials(provider: Provider) async {
        guard let request = Request.token(provider: provider) else { return }
        guard let (data, response) = try? await urlSession.data(for: request) else {
            return publish(state: .empty)
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        // Decode the token
        guard let token = try? decoder.decode(Token.self, from: data) else {
            return publish(state: .empty)
        }

        // Store the authorization
        let authorization = Authorization(issuer: provider.id, token: token)
        guard let stored = try? keychain.set(authorization, for: authorization.issuer), stored else {
            return publish(state: .empty)
        }
        publish(state: .authorized(provider, authorization))
    }

    /// Polls the oauth provider's access token endpoint until the device code has expired or we've successfully received an auth token.
    /// See: https://oauth.net/2/grant-types/device-code/
    /// - Parameters:
    ///   - provider: the provider to poll
    ///   - deviceCode: the device code to use
    func poll(provider: Provider, deviceCode: DeviceCode) async {

        guard !deviceCode.isExpired, let request = Request.token(provider: provider, deviceCode: deviceCode) else {
            return publish(state: .empty)
        }

        guard let (data, response) = try? await urlSession.data(for: request) else {
            return publish(state: .empty)
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        /// If we received something other than a 200 response or we can't decode the token then restart the polling
        guard response.isOK, let token = try? decoder.decode(Token.self, from: data) else {
            // Reschedule the polling task
            return schedule(provider: provider, deviceCode: deviceCode)
        }

        // Store the authorization
        let authorization = Authorization(issuer: provider.id, token: token)
        guard let stored = try? keychain.set(authorization, for: authorization.issuer), stored else {
            return publish(state: .empty)
        }
        publish(state: .authorized(provider, authorization))
    }
}
