//
//  OAuth+Provider.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// Provides configuration data for an OAuth service provider.
    public struct Provider: Codable, Identifiable, Hashable, Sendable {

        /// The provider unique id.
        public var id: String
        /// The provider icon.
        public var icon: URL?
        /// The provider authorization url.
        var authorizationURL: URL
        /// The provider access token url.
        var accessTokenURL: URL
        /// The provider device code url that can be used for devices without browsers (like tvOS).
        var deviceCodeURL: URL?
        /// The unique client identifier tforinteracting with this providers oauth server.
        var clientID: String
        /// The client's secret known only to the client and the providers oauth server. It is essential the client's password.
        var clientSecret: String
        /// The provider redirect uri.
        var redirectURI: String?
        /// The provider scopes.
        var scope: [String]?
        /// Informs the oauth client to encode the access token query parameters into the
        /// http body (using application/x-www-form-urlencoded) or simply send the query parameters with the request.
        /// This is turned on by default, but you may need to disable this based on how the provider is implemented.
        var encodeHttpBody: Bool
        /// The custom user agent to send with browser requests. Providers such as Slack will block unsupported browsers
        /// from initiating oauth workflows. Setting this value to a supported user agent string can allow for workarounds.
        /// Be very careful when setting this value as it can have unintended consquences of how servers respond to requests.
        var customUserAgent: String?

        /// The coding keys.
        enum CodingKeys: String, CodingKey {
            case id
            case icon
            case authorizationURL
            case accessTokenURL
            case deviceCodeURL
            case clientID
            case clientSecret
            case redirectURI
            case scope
            case encodeHttpBody
            case customUserAgent
        }

        /// Custom decoder initializer.
        /// - Parameters:
        ///   - decoder: the decoder to use
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            icon = try container.decodeIfPresent(URL.self, forKey: .icon)
            authorizationURL = try container.decode(URL.self, forKey: .authorizationURL)
            accessTokenURL = try container.decode(URL.self, forKey: .accessTokenURL)
            deviceCodeURL = try container.decodeIfPresent(URL.self, forKey: .deviceCodeURL)
            clientID = try container.decode(String.self, forKey: .clientID)
            clientSecret = try container.decode(String.self, forKey: .clientSecret)
            redirectURI = try container.decodeIfPresent(String.self, forKey: .redirectURI)
            scope = try container.decodeIfPresent([String].self, forKey: .scope)
            encodeHttpBody = try container.decodeIfPresent(Bool.self, forKey: .encodeHttpBody) ?? true
            customUserAgent = try container.decodeIfPresent(String.self, forKey: .customUserAgent)
        }

        /// Builds an url request for the specified grant type.
        /// - Parameters:
        ///   - grantType: the grant type to build a request for
        ///   - token: the current access token
        /// - Returns: an url request or nil
        public func request(grantType: GrantType, token: Token? = nil) -> URLRequest? {

            var urlComponents = URLComponents()
            var queryItems = [URLQueryItem]()

            switch grantType {
            case .authorizationCode(let state):
                guard let components = URLComponents(string: authorizationURL.absoluteString) else {
                    return nil
                }
                urlComponents = components
                queryItems.append(URLQueryItem(name: "client_id", value: clientID))
                queryItems.append(URLQueryItem(name: "redirect_uri", value: redirectURI))
                queryItems.append(URLQueryItem(name: "response_type", value: "code"))
                queryItems.append(URLQueryItem(name: "state", value: state))
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
            case .clientCredentials:
                fatalError("TODO: Not implemented")
            case .pkce(let pkce):
                guard let components = URLComponents(string: authorizationURL.absoluteString) else {
                    return nil
                }
                urlComponents = components
                queryItems.append(URLQueryItem(name: "client_id", value: clientID))
                queryItems.append(URLQueryItem(name: "redirect_uri", value: redirectURI))
                queryItems.append(URLQueryItem(name: "response_type", value: "code"))
                queryItems.append(URLQueryItem(name: "state", value: pkce.state))
                queryItems.append(URLQueryItem(name: "code_challenge", value: pkce.codeChallenge))
                queryItems.append(URLQueryItem(name: "code_challenge_method", value: pkce.codeChallengeMethod))
                if let scope {
                    queryItems.append(URLQueryItem(name: "scope", value: scope.joined(separator: " ")))
                }
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
}
