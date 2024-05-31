//
//  OAuth.swift
//
//
//  Created by Kevin McKee on 5/14/24.
//
import Combine
import CryptoKit
import Foundation

/// The default file name that holds the list of providers.
private let defaultResourceName = "oauth"
/// The default file extension.
private let defaultExtension = "json"

/// Provides an enum error that provides
public enum OAError: Error {
    case unknown
    case malformedURL
    case badResponse
    case decoding
    case keychain
}

/// Provides an observable OAuth 2.0 implementation.
public class OAuth: NSObject, ObservableObject {

    /// Keys and values used to specify loading or runtime options.
    public struct Option: Hashable, Equatable, RawRepresentable, @unchecked Sendable {

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
    public enum GrantType: String, Codable {
        case authorizationCode
        case clientCredentials = "client_credentials"
        case deviceCode = "device_code"
        case pkce
        case refreshToken = "refresh_token"
    }

    /// Provides configuration data for an OAuth service provider.
    public struct Provider: Codable, Identifiable, Hashable {

        public var id: String
        public var icon: URL?
        var authorizationURL: URL
        var accessTokenURL: URL
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
            case .clientCredentials:
                break
            case .deviceCode:
                break
            case .pkce:
                fatalError("Not implemented")
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
    public struct Token: Codable, Equatable {

        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?
        let state: String?
        let type: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case type = "token_type"
            case state
        }
    }

    /// A codable type that holds authorization information that can be stored.
    public struct Authorization: Codable, Equatable {

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
        init(issuer: String, token: Token, issued: Date = Date.now) {
            self.issuer = issuer
            self.token = token
            self.issued = issued
        }

        /// Returns true if the token is expired or not.
        public var isExpired: Bool {
            guard let expiresIn = token.expiresIn else { return false }
            return issued.addingTimeInterval(Double(expiresIn)) < Date.now
        }
    }

    /// Holds the OAuth state that is published to subscribers via the `state` property publisher.
    public enum State: Equatable {

        /// The state is empty and no authorizations or tokens have been issued.
        case empty

        /// The OAuth authorization step has been started for the specifed provider.
        /// - Parameters:
        ///   - Provider: the oauth provider
        case authorizing(Provider)

        /// An access token is being requested for the specifed provider..
        /// - Parameters:
        ///   - Provider: the oauth provider
        case requestingAccessToken(Provider)

        /// An authorization has been granted.
        /// - Parameters:
        ///   - Authorization: the oauth authorization
        case authorized(Authorization)
    }

    /// A published list of available OAuth providers to choose from.
    @Published
    public var providers = [Provider]()

    @Published
    public var state: State = .empty

    /// The url session to use for communicating with providers.
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: URLSessionConfiguration.default)
    }()

    private var tasks = [Task<(), any Error>]()
    private var options: [Option: Any]?
    private let networkMonitor = NetworkMonitor()
    private var keychain: Keychain = .default

    /// Combine subscribers.
    private var subscribers = Set<AnyCancellable>()

    /// Initializes the OAuth service with the specified providers.
    /// - Parameters:
    ///   - providers: the list of oauth providers
    public init(providers: [Provider] = [Provider](), options: [Option: Any]? = nil) {
        self.options = options
        self.providers = providers
        super.init()
        start()
    }

    /// Common Initializer that attempts to load an `oauth.json` file from the specified bundle.
    /// - Parameters:
    ///   - bundle: the bundle to load the oauth provider configuration information from.
    ///   - options: the initialization options to apply
    public init(_ bundle: Bundle, options: [Option: Any]? = nil) {
        self.options = options
        if let url = bundle.url(forResource: defaultResourceName, withExtension: defaultExtension),
              let data = try? Data(contentsOf: url),
              let providers = try? JSONDecoder().decode([Provider].self, from: data) {
            self.providers = providers
        }
        super.init()
        start()
    }

    /// Performs post init operations.
    private func start() {

        // Initialize with custom options
        if let options {
            // Use the custom application tag
            if let applicationTag = options[.applicationTag] as? String, applicationTag.isNotEmpty {
                self.keychain = Keychain(applicationTag)
            }
        }
        restore()
        subscribe()
    }

    /// Restores state from storage.
    private func restore() {
        for provider in providers {
            if let authorization: OAuth.Authorization = try? keychain.get(key: provider.id), !authorization.isExpired {
                publish(state: .authorized(authorization))
                break
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
    /// - Parameter provider: the provider to being authorization for
    func authorize(provider: Provider) {
        state = .authorizing(provider)
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
        let decoder = JSONDecoder()
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

    /// Removes all tokens and clears the OAuth state
    func clear() {
        debugPrint("⚠️ [Clearing oauth state]")
        keychain.clear()
        publish(state: .empty)
    }

    /// Attempts to refresh the current access token.
    /// See: https://datatracker.ietf.org/doc/html/rfc6749#section-6
    private func refresh() async {
        switch state {
        case .empty, .authorizing, .requestingAccessToken:
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
                publish(state: .empty)
                return
            }

            // Decode the token
            let decoder = JSONDecoder()
            guard let token = try? decoder.decode(Token.self, from: data) else {
                publish(state: .empty)
                return
            }

            // Store the authorization
            let authorization = Authorization(issuer: provider.id, token: token)
            guard let stored = try? keychain.set(authorization, for: authorization.issuer), stored else {
                publish(state: .empty)
                return
            }
            publish(state: .authorized(authorization))
        }
    }

    /// Publishes state on the main thread.
    /// - Parameter state: the new state information to publish out on the main thread.
    private func publish(state: State) {
        switch state {
        case .authorized(let auth):
            if let options, let autoRefresh = options[.autoRefresh] as? Bool, autoRefresh {
                // Schedule the refresh task
                if let expiresIn = auth.token.expiresIn {
                    // TODO: Calculate the timeInterval when being restored on launch
                    let timeInterval = Double(expiresIn)
                    let task = Task.delayed(timeInterval: timeInterval) {
                        await self.refresh()
                    }
                    tasks.append(task)
                }
            }
        case .empty, .authorizing, .requestingAccessToken:
            break
        }
        DispatchQueue.main.async {
            self.state = state
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

