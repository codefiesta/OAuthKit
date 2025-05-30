//
//  OAuth.swift
//
//
//  Created by Kevin McKee on 5/14/24.
//
import Combine
import CryptoKit
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
    public enum Storage: String {
        /// Tokens are stored inside Keychain (recommended).
        case keychain
        /// Tokens are stored inside SwiftData.
        case swiftdata
        /// Tokens are stored in memory only.
        case memory
    }

    /// Provides an enum representation for the OAuth 2.0 Grant Types.
    ///
    /// See: https://oauth.net/2/grant-types/
    public enum GrantType: String, Codable, Sendable {
        case authorizationCode
        case clientCredentials = "client_credentials"
        case deviceCode = "device_code"
        case pkce
        case refreshToken = "refresh_token"
    }

    /// Provides configuration data for an OAuth service provider.
    public struct Provider: Codable, Identifiable, Hashable, Sendable {

        public var id: String
        public var icon: URL?
        var authorizationURL: URL
        var accessTokenURL: URL
        var deviceCodeURL: URL?
        fileprivate var clientID: String
        fileprivate var clientSecret: String
        var redirectURI: String?
        var scope: [String]?

        /// Builds an url request for the specified grant type.
        /// - Parameters:
        ///   - grantType: the grant type to build a request for
        ///   - token: the current access token
        /// - Returns: an url request or nil
        public func request(grantType: GrantType, token: Token? = nil) -> URLRequest? {

            var urlComponents = URLComponents()
            var queryItems = [URLQueryItem]()

            switch grantType {
            case .authorizationCode:
                guard let components = URLComponents(string: authorizationURL.absoluteString) else {
                    return nil
                }
                urlComponents = components
                queryItems.append(URLQueryItem(name: "client_id", value: clientID))
                queryItems.append(URLQueryItem(name: "redirect_uri", value: redirectURI))
                queryItems.append(URLQueryItem(name: "response_type", value: "code"))
                if let scope {
                    queryItems.append(URLQueryItem(name: "scope", value: scope.joined(separator: " ")))
                }
            case .deviceCode:
                guard let deviceCodeURL, let components = URLComponents(string: deviceCodeURL.absoluteString) else {
                    return nil
                }
                urlComponents = components
                queryItems.append(URLQueryItem(name: "client_id", value: clientID))
                if let scope {
                    queryItems.append(URLQueryItem(name: "scope", value: scope.joined(separator: " ")))
                }
            case .clientCredentials, .pkce:
                fatalError("TODO: Not implemented")
            case .refreshToken:
                guard let refreshToken = token?.refreshToken, let components = URLComponents(string: authorizationURL.absoluteString) else {
                    return nil
                }
                urlComponents = components
                queryItems.append(URLQueryItem(name: "client_id", value: clientID))
                queryItems.append(URLQueryItem(name: "grant_type", value: grantType.rawValue))
                queryItems.append(URLQueryItem(name: "refresh_token", value: refreshToken))
            }
            urlComponents.queryItems = queryItems
            guard let url = urlComponents.url else { return nil }
            return URLRequest(url: url)
        }
    }

    /// A codable type that holds oauth token information.
    /// See: https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-5.1
    public struct Token: Codable, Equatable, Sendable {

        public let accessToken: String
        public let refreshToken: String?
        public let expiresIn: Int?
        public let state: String?
        public let type: String

        public init(accessToken: String, refreshToken: String?, expiresIn: Int?, state: String?, type: String) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.state = state
            self.type = type
        }

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case type = "token_type"
            case state
        }
    }

    /// A codable type that holds device code information.
    /// See: https://auth0.com/docs/get-started/authentication-and-authorization-flow/device-authorization-flow
    /// See: https://www.oauth.com/playground/device-code.html
    public struct DeviceCode: Codable, Equatable, Sendable {

        /// The server assigned device code.
        public let deviceCode: String
        /// The code the user should enter when visiting the `verificationUri`
        public let userCode: String
        /// The uri the user should visit to enter the `userCode`
        public let verificationUri: String
        /// Either a QR Code or shortened URL with embedded user code
        public let verificationUriComplete: String?
        /// The lifetime in seconds for `deviceCode` and `userCode`
        public let expiresIn: Int?
        /// The polling interval
        public let interval: Int
        /// The issue date.
        public let issued: Date = .now

        public init(deviceCode: String, userCode: String,
                    verificationUri: String, verificationUriComplete: String? = nil,
                    expiresIn: Int?, interval: Int) {
            self.deviceCode = deviceCode
            self.userCode = userCode
            self.verificationUri = verificationUri
            self.verificationUriComplete = verificationUriComplete
            self.expiresIn = expiresIn
            self.interval = interval
        }

        enum CodingKeys: String, CodingKey {
            case deviceCode = "device_code"
            case userCode = "user_code"
            case verificationUri = "verification_uri"
            case verificationUriComplete = "verification_uri_complete"
            case expiresIn = "expires_in"
            case interval
        }

        /// Returns true if the device code is expired.
        public var isExpired: Bool {
            guard let expiresIn = expiresIn else { return false }
            return issued.addingTimeInterval(Double(expiresIn)) < Date.now
        }

        /// Returns the expiration date of the device token or nil if none exists.
        public var expiration: Date? {
            guard let expiresIn = expiresIn else { return nil }
            return issued.addingTimeInterval(TimeInterval(expiresIn))
        }
    }

    /// A codable type that holds authorization information that can be stored.
    public struct Authorization: Codable, Equatable, Sendable {

        /// The provider ID that issued the authorization.
        public let issuer: String
        /// The issue date.
        public let issued: Date
        /// The issued access token.
        public let token: Token

        /// Initializer
        /// - Parameters:
        ///   - issuer: the provider ID that issued the authorization.
        ///   - token: the access token
        ///   - issued: the issued date
        public init(issuer: String, token: Token, issued: Date = Date.now) {
            self.issuer = issuer
            self.token = token
            self.issued = issued
        }

        /// Returns true if the token is expired.
        public var isExpired: Bool {
            guard let expiresIn = token.expiresIn else { return false }
            return issued.addingTimeInterval(Double(expiresIn)) < Date.now
        }

        /// Returns the expiration date of the authorization or nil if none exists.
        public var expiration: Date? {
            guard let expiresIn = token.expiresIn else { return nil }
            return issued.addingTimeInterval(TimeInterval(expiresIn))
        }
    }

    /// Holds the OAuth state that is published to subscribers via the `state` property publisher.
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
        ///   - Authorization: the oauth authorization
        case authorized(Authorization)
    }

    /// A published list of available OAuth providers to choose from.
    public var providers = [Provider]()

    /// An observable  published oauth state.
    public var state: State = .empty

    /// The url session to use for communicating with providers.
    @ObservationIgnored
    private lazy var urlSession: URLSession = {
        .init(configuration: .default)
    }()

    @ObservationIgnored
    private var tasks = [Task<(), any Error>]()
    @ObservationIgnored
    private var options: [Option: Sendable]?
    @ObservationIgnored
    private let networkMonitor = NetworkMonitor()
    @ObservationIgnored
    private var keychain: Keychain = .default

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
        Task {
            await start()
        }
    }

    /// Common Initializer that attempts to load an `oauth.json` file from the specified bundle.
    /// - Parameters:
    ///   - bundle: the bundle to load the oauth provider configuration information from.
    ///   - options: the initialization options to apply
    public init(_ bundle: Bundle, options: [Option: Sendable]? = nil) {
        super.init()
        self.options = options
        self.providers = loadProviders(bundle)
        Task {
            await start()
        }
    }

    /// Loads providers from the specified bundle.
    /// - Parameter bundle: the bundle to load the oauth provider configuration information from.
    /// - Returns: found providers in the specifed bundle or an empty list if not found
    private func loadProviders(_ bundle: Bundle) -> [Provider] {
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: defaultExtension),
              let data = try? Data(contentsOf: url),
              let providers = try? decoder.decode([Provider].self, from: data) else {
            return []
        }
        return providers
    }

    /// Performs post init operations.
    private func start() async {
        // Initialize with custom options
        if let options {
            // Use the custom application tag
            if let applicationTag = options[.applicationTag] as? String, applicationTag.isNotEmpty {
                self.keychain = Keychain(applicationTag)
            }
        }
        subscribe()
        await restore()
    }

    /// Restores state from storage.
    private func restore() async {
        for provider in providers {
            if let authorization: OAuth.Authorization = try? keychain.get(key: provider.id), !authorization.isExpired {
                publish(state: .authorized(authorization))
            }
        }
    }

    /// Subsribes to event publishers.
    private func subscribe() {
        // Subscribe to network status events
        networkMonitor.networkStatus.sink { (_) in
            // TODO: Add Handler
        }.store(in: &subscribers)
    }
}

public extension OAuth {

    /// Starts the authorization process for the specified provider.
    /// - Parameters:
    ///   - provider: the provider to begin authorization for
    ///   - grantType: the grant type to execute
    func authorize(provider: Provider, grantType: GrantType = .authorizationCode) {
        switch grantType {
        case .authorizationCode:
            state = .authorizing(provider, grantType)
        case .deviceCode:
            Task {
                await requestDeviceCode(provider: provider)
            }
        case .clientCredentials, .pkce, .refreshToken:
            break
        }
    }

    /// Requests to exchange a code for an access token.
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
    /// - Parameters:
    ///   - provider: the provider the access token is being requested from
    ///   - code: the code to exchange
    /// - Returns: the exchange result
    @discardableResult
    func requestAccessToken(provider: Provider, code: String) async -> Result<Token, OAError> {
        // Publish the state
        publish(state: .requestingAccessToken(provider))
        guard var urlComponents = URLComponents(string: provider.accessTokenURL.absoluteString) else {
            publish(state: .empty)
            return .failure(.malformedURL)
        }
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "client_id", value: provider.clientID))
        queryItems.append(URLQueryItem(name: "client_secret", value: provider.clientSecret))
        queryItems.append(URLQueryItem(name: "code", value: code))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: provider.redirectURI))
        queryItems.append(URLQueryItem(name: "grant_type", value: "authorization_code"))
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            publish(state: .empty)
            return .failure(.malformedURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await urlSession.data(for: request) else {
            publish(state: .empty)
            return .failure(.badResponse)
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

        publish(state: .authorized(authorization))
        return .success(token)
    }

    /// Requests a device code from the specified provider.
    /// - Parameters:
    ///   - provider: the provider the device code is being requested from
    private func requestDeviceCode(provider: Provider) async {
        // Publish the state
        publish(state: .requestingDeviceCode(provider))
        guard var request = provider.request(grantType: .deviceCode) else { return }

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await urlSession.data(for: request) else {
            publish(state: .empty)
            return
        }

        // Decode the device code
        guard let deviceCode = try? decoder.decode(DeviceCode.self, from: data) else {
            publish(state: .empty)
            return
        }

        // Publish the state
        publish(state: .receivedDeviceCode(provider, deviceCode))
    }

    /// Removes all tokens and clears the OAuth state
    func clear() {
        Task {
            debugPrint("⚠️ [Clearing oauth state]")
            keychain.clear()
            publish(state: .empty)
        }
    }

    /// Publishes state on the main thread.
    /// - Parameter state: the new state information to publish out on the main thread.
    private func publish(state: State) {
        switch state {
        case .authorized(let auth):
            schedule(auth: auth)
        case .receivedDeviceCode(let provider, let deviceCode):
            schedule(provider: provider, deviceCode: deviceCode)
        case .empty, .authorizing, .requestingAccessToken, .requestingDeviceCode:
            break
        }
        self.state = state
    }

    /// Attempts to refresh the current access token.
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-6
    private func refresh() async {
        switch state {
        case .empty, .authorizing, .requestingAccessToken, .requestingDeviceCode, .receivedDeviceCode:
            return
        case .authorized(let auth):
            guard let provider = providers.filter({ $0.id == auth.issuer }).first else {
                return
            }

            // If we can't build a refresh request and the token is expired, simply clear the token and state
            guard var request = provider.request(grantType: .refreshToken, token: auth.token) else {
                if auth.isExpired { clear() }
                return
            }

            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            guard let (data, _) = try? await urlSession.data(for: request) else {
                return publish(state: .empty)
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
            publish(state: .authorized(authorization))
        }
    }

    /// Polls the oauth provider's access token endpoint until the device code has expired or we've successfully received an auth token.
    /// See: https://oauth.net/2/grant-types/device-code/
    /// - Parameters:
    ///   - provider: the provider to poll
    ///   - deviceCode: the device code to use
    private func poll(provider: Provider, deviceCode: DeviceCode) async {

        guard !deviceCode.isExpired, var urlComponents = URLComponents(string: provider.accessTokenURL.absoluteString) else {
            publish(state: .empty)
            return
        }

        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "client_id", value: provider.clientID))
        queryItems.append(URLQueryItem(name: "grant_type", value: "urn:ietf:params:oauth:grant-type:device_code"))
        queryItems.append(URLQueryItem(name: "device_code", value: deviceCode.deviceCode))
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            publish(state: .empty)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await urlSession.data(for: request) else {
            publish(state: .empty)
            return
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
        publish(state: .authorized(authorization))
    }

    /// Schedules the provider to be polled for authorization with the specified device token.
    /// - Parameters:
    ///   - provider: the oauth provider
    ///   - deviceCode: the device code issued by the provider
    private func schedule(provider: Provider, deviceCode: DeviceCode) {
        let timeInterval: TimeInterval = .init(deviceCode.interval)
        let task = Task.delayed(timeInterval: timeInterval) { [weak self] in
            guard let self else { return }
            await self.poll(provider: provider, deviceCode: deviceCode)
        }
        tasks.append(task)
    }

    /// Schedules refresh tasks for the specified authorization.
    /// - Parameter auth: the authentication to schedule a future tasks for
    private func schedule(auth: Authorization) {
        if let options, let autoRefresh = options[.autoRefresh] as? Bool, autoRefresh {
            if let expiration = auth.expiration {
                let timeInterval = expiration - Date.now
                if timeInterval > 0 {
                    // Schedule the refresh task
                    let task = Task.delayed(timeInterval: timeInterval) { [weak self] in
                        guard let self else { return }
                        await self.refresh()
                    }
                    tasks.append(task)
                } else {
                    // Execute the task immediately
                    Task {
                        await refresh()
                    }
                }
            }
        }
    }
}

// MARK: Options

public extension OAuth.Option {

    /// A key used to specify whether tokens should be automatically refreshed or not.
    static let autoRefresh: OAuth.Option = .init(rawValue: "autoRefresh")

    /// A key used for custom application identifiers to improve token tagging.
    static let applicationTag: OAuth.Option = .init(rawValue: "applicationTag")

}

