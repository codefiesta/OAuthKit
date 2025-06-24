//
//  OAuth.swift
//
//
//  Created by Kevin McKee on 5/14/24.
//
import Combine
import Foundation
import LocalAuthentication
import Observation

/// The default file name that holds the list of providers.
private let defaultResourceName = "oauth"
/// The default file extension.
private let defaultExtension = "json"
/// The default reason for local authentication with biometrics or companion device.
private let defaultAuthenticationWithBiometricsOrCompanionReason = "unlock keychain"

/// Provides an enum of oauth errors.
public enum OAError: Error {
    case unknown
    case malformedURL
    case badResponse
    case decoding
    case keychain
}

/// Provides an observable OAuth 2.0 implementation.
/// See: https://datatracker.ietf.org/doc/html/rfc6749
@MainActor
@Observable
public final class OAuth: NSObject {

    /// Keys and values used to specify loading or runtime options.
    public struct Option: Hashable, Equatable, RawRepresentable, Sendable {

        /// The option raw value.
        public var rawValue: String

        /// Initializer
        /// - Parameter rawValue: the option raw value
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// A published list of available OAuth providers to choose from.
    public var providers = [Provider]()

    /// An observable  published oauth state.
    public var state: State = .empty

    /// The url session to use for communicating with providers.
    @ObservationIgnored
    public var urlSession: URLSession = .init(configuration: .ephemeral)
    @ObservationIgnored
    private var tasks = [Task<(), any Error>]()
    @ObservationIgnored
    private let networkMonitor = NetworkMonitor()
    @ObservationIgnored
    var keychain: Keychain = .default

    #if os(macOS) || os(iOS) || os(visionOS)
    @ObservationIgnored
    var context: LAContext = .init()
    #endif

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

    /// Combine subscribers.
    @ObservationIgnored
    private var subscribers = Set<AnyCancellable>()

    /// The json decoder
    @ObservationIgnored
    private let decoder: JSONDecoder = .init()

    /// Initializes the OAuth service with the specified providers and configuration options.
    /// - Parameters:
    ///   - providers: the list of oauth providers
    ///   - options: the configuration options to apply
    public init(providers: [Provider] = [Provider](), options: [Option: Any]? = nil) {
        super.init()
        self.providers = providers
        configure(options)
    }

    /// Common Initializer that attempts to load an `oauth.json` file from the specified bundle.
    /// - Parameters:
    ///   - bundle: the bundle to load the oauth provider configuration information from.
    ///   - options: the configuration options to apply
    public init(_ bundle: Bundle, options: [Option: Any]? = nil) {
        super.init()
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
        subscribe()
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

    /// Subsribes to event publishers.
    func subscribe() {
        // Subscribe to network status events
        networkMonitor.networkStatus.sink { (_) in
            // TODO: Add Handler
        }.store(in: &subscribers)
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
        guard let auth: OAuth.Authorization = try? keychain.get(key: provider.id) else {
            return
        }

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
            publish(state: .empty)
            return
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        // Decode the device code
        guard let deviceCode = try? decoder.decode(DeviceCode.self, from: data) else {
            publish(state: .empty)
            return
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
            publish(state: .empty)
            return
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
            publish(state: .empty)
            return
        }

        guard let (data, response) = try? await urlSession.data(for: request) else {
            publish(state: .empty)
            return
        }

        if provider.debug {
            let statusCode = response.statusCode() ?? -1
            let rawData = String(data: data, encoding: .utf8) ?? .empty
            debugPrint("Response: [\(statusCode))]", "Data: [\(rawData)]")
        }

        /// If we received something other than a 200 response or we can't decode the token then restart the polling
        guard response.isOK, let token = try? decoder.decode(Token.self, from: data) else {
            // Reschedule the polling task
            schedule(provider: provider, deviceCode: deviceCode)
            return
        }

        // Store the authorization
        let authorization = Authorization(issuer: provider.id, token: token)
        guard let stored = try? keychain.set(authorization, for: authorization.issuer), stored else {
            return publish(state: .empty)
        }
        publish(state: .authorized(provider, authorization))
    }
}


// MARK: Options

public extension OAuth.Option {

    /// A key used for custom application identifiers to improve token tagging.
    static let applicationTag: OAuth.Option = .init(rawValue: "applicationTag")

    /// A key used to specify whether tokens should be automatically refreshed or not.
    static let autoRefresh: OAuth.Option = .init(rawValue: "autoRefresh")

    /// A key used for providing a custom local authentication object.
    static let localAuthentication: OAuth.Option = .init(rawValue: "localAuthentication")

    /// A key used for determining if the keychain should be protected with biometrics until successful local authentication.
    /// If set to true, the device owner will need to be authenticated by biometry or a companion device before the keychain items can be accessed.
    /// Important: developers should set the requireAuthenticationWithBiometricsOrCompanionReason that will be eventually displayed in the authentication dialog.
    static let requireAuthenticationWithBiometricsOrCompanion: OAuth.Option = . init(rawValue: "requireAuthenticationWithBiometricsOrCompanion")

    /// A key used for providing a custom url session.
    static let urlSession: OAuth.Option = .init(rawValue: "urlSession")

    /// A key used for setting the WKWebsiteDataStore to `nonPersistent()` in the OAWebView.
    /// This is disabled by default, but this can be turned on to allow developers to use an ephemeral webkit datastore
    /// that effectively implements private browsing and forces a new login attempt every time an authorization flow is started.
    static let useNonPersistentWebDataStore: OAuth.Option = .init(rawValue: "useNonPersistentWebDataStore")
}

