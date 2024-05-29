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
        var clientID: String
        var clientSecret: String
        var redirectURI: String?
        var scope: [String]?

        /// Builds an url request for the specified grant type.
        /// - Parameter grantType: the grant type to build a request for
        /// - Returns: an url request or nil
        public func request(grantType: GrantType) -> URLRequest? {

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
                break
            }
            urlComponents.queryItems = queryItems
            guard let url = urlComponents.url else { return nil }
            return URLRequest(url: url)
        }
    }

    /// A codable type that holds oauth token information.
    /// See: https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/
    public struct Token: Codable, Equatable {

        let accessToken: String
        let expiresIn: Int64?
        let state: String?
        let type: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case type = "token_type"
            case state
        }
    }

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

        /// The OAuth provider has been issued an access token is authorized to access resources.
        /// - Parameters:
        ///   - Provider: the oauth provider
        case authorized(Token)
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

    /// Initializes the OAuth service with the specified providers.
    /// - Parameters:
    ///   - providers: the list of oauth providers
    public init(providers: [Provider] = [Provider]()) {
        self.providers = providers
    }

    /// Common Initializer that attempts to load an `oauth.json` file from the specified bundle.
    /// - Parameters:
    ///   - bundle: the bundle to load the oauth provider configuration information from.
    ///   - options: the initialization options to apply
    public init(_ bundle: Bundle, options: [Option: Any]? = nil) {
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: defaultExtension),
              let data = try? Data(contentsOf: url),
              let providers = try? JSONDecoder().decode([Provider].self, from: data) else {
            return
        }
        debugPrint("✅ [Registering OAuth Providers]: [\(providers.count)] ")
        self.providers = providers
        // TODO: Implement storage options
    }
}

public extension OAuth {

    func authorize(provider: Provider) {
        state = .authorizing(provider)
    }

    @discardableResult
    func requestAccessToken(provider: Provider, code: String) async -> Result<Token, OAError> {
        debugPrint("✅ [Requesting access token]", provider.id, code)
        guard var urlComponents = URLComponents(string: provider.accessTokenURL.absoluteString) else {
            return .failure(.malformedURL)
        }
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "client_id", value: provider.clientID))
        queryItems.append(URLQueryItem(name: "client_secret", value: provider.clientSecret))
        queryItems.append(URLQueryItem(name: "code", value: code))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: provider.redirectURI))
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            return .failure(.malformedURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await urlSession.data(for: request) else {
            return .failure(.badResponse)
        }

        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(Token.self, from: data) else {
            return .failure(.decoding)
        }
        return .success(token)
    }
}

// MARK: Options

public extension OAuth.Option {

    /// A key used to specify whether tokens should be stored in keychain or not.
    static let keychainStorage: OAuth.Option = .init(rawValue: "keychainStorage")

}

