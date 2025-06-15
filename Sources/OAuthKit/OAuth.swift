//
//  OAuth.swift
//
//
//  Created by Kevin McKee on 5/14/24.
//
import Combine
import Foundation
import Observation

/// The default file name that holds the list of providers.
private let defaultResourceName = "oauth"
/// The default file extension.
private let defaultExtension = "json"

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

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Provides an enum representation for token storage options.
    /// Future enhancement - all tokens are currently stored inside the Keychain.
    public enum Storage: String {
        /// Tokens are stored inside Keychain (recommended).
        case keychain
        /// Tokens are stored inside SwiftData.
        case swiftdata
        /// Tokens are stored in memory only.
        case memory
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
    private var options: [Option: Sendable]?
    @ObservationIgnored
    private let networkMonitor = NetworkMonitor()
    @ObservationIgnored
    var keychain: Keychain = .default

    /// Combine subscribers.
    @ObservationIgnored
    private var subscribers = Set<AnyCancellable>()

    /// The json decoder
    @ObservationIgnored
    private let decoder: JSONDecoder = .init()

    /// Initializes the OAuth service with the specified providers.
    /// - Parameters:
    ///   - providers: the list of oauth providers
    public init(providers: [Provider] = [Provider](), options: [Option: Sendable]? = nil) {
        super.init()
        self.options = options
        self.providers = providers
        // Set the keychain
        if let options, let applicationTag = options[.applicationTag] as? String, applicationTag.isNotEmpty {
            // Override the keychain to use the custom application tag
            self.keychain = .init(applicationTag)
        }
        start()
    }

    /// Common Initializer that attempts to load an `oauth.json` file from the specified bundle.
    /// - Parameters:
    ///   - bundle: the bundle to load the oauth provider configuration information from.
    ///   - options: the initialization options to apply
    public init(_ bundle: Bundle, options: [Option: Sendable]? = nil) {
        super.init()
        self.options = options
        self.providers = loadProviders(bundle)
        // Set the keychain
        if let options, let applicationTag = options[.applicationTag] as? String, applicationTag.isNotEmpty {
            // Override the keychain to use the custom application tag
            self.keychain = .init(applicationTag)
        }
        start()
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

    /// Performs post init operations.
    func start() {
        subscribe()
        restore()
    }

    /// Restores state from storage.
    func restore() {
        for provider in providers {
            if let authorization: OAuth.Authorization = try? keychain.get(key: provider.id), !authorization.isExpired {
                publish(state: .authorized(provider, authorization))
            }
        }
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

        if let options, let autoRefreshEnabled = options[.autoRefresh] as? Bool, autoRefreshEnabled {
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
                    Task {
                        await refreshToken(provider: provider)
                    }
                }
            }
        }
    }
}

// MARK: URLRequests

fileprivate extension OAuth {

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

    /// A key used to specify whether tokens should be automatically refreshed or not.
    static let autoRefresh: OAuth.Option = .init(rawValue: "autoRefresh")

    /// A key used for custom application identifiers to improve token tagging.
    static let applicationTag: OAuth.Option = .init(rawValue: "applicationTag")

}

