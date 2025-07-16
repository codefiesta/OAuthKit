//
//  OAuth+Provider.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// Provides configuration data for an OAuth 2.0 service provider.
    public struct Provider: Codable, Identifiable, Hashable, Sendable {

        /// The provider unique id.
        public var id: String
        /// The provider icon.
        public var icon: URL?
        /// The provider authorization url.
        public var authorizationURL: URL
        /// The provider access token url.
        public var accessTokenURL: URL
        /// The provider device code url that can be used for devices without browsers (like tvOS).
        public var deviceCodeURL: URL?
        /// The provider redirect uri.
        public var redirectURI: String?
        /// The unique client identifier for interacting with this providers oauth server.
        var clientID: String
        /// The client's secret known only to the client and the providers oauth server. It is essential the client's password.
        var clientSecret: String?
        /// The provider scopes.
        public var scope: [String]?
        /// Informs the oauth client to encode the access token query parameters into the
        /// http body (using application/x-www-form-urlencoded) or simply send the query parameters with the request.
        /// This is turned on by default, but you may need to disable this based on how the provider is implemented.
        public var encodeHttpBody: Bool
        /// The custom user agent to send with browser requests. Providers such as Slack will block unsupported browsers
        /// from initiating oauth workflows. Setting this value to a supported user agent string can allow for workarounds.
        /// Be very careful when setting this value as it can have unintended consquences of how servers respond to requests.
        public var customUserAgent: String?
        /// Enables provider debugging. Off by default.
        public var debug: Bool

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
            case debug
        }

        /// Public initializer.
        /// - Parameters:
        ///   - id: The provider unique id
        ///   - icon: The provider icon
        ///   - authorizationURL: The provider authorization url.
        ///   - accessTokenURL: The provider access token url.
        ///   - deviceCodeURL: The provider device code url.
        ///   - clientID: The client id
        ///   - clientSecret: The client secret
        ///   - redirectURI: The redirect uri
        ///   - scope: The oauth scope
        ///   - encodeHttpBody: If the provider should encode the access token parameters into the http body (true by default)
        ///   - customUserAgent: The custom user agent to send with browser requests.
        ///   - debug: Boolean to pass debugging into to the standard output (false by default)
        public init(id: String,
                    icon: URL? = nil,
                    authorizationURL: URL,
                    accessTokenURL: URL,
                    deviceCodeURL: URL? = nil,
                    clientID: String,
                    clientSecret: String?,
                    redirectURI: String? = nil,
                    scope: [String]? = nil,
                    encodeHttpBody: Bool = true,
                    customUserAgent: String? = nil,
                    debug: Bool = false) {
            self.id = id
            self.icon = icon
            self.authorizationURL = authorizationURL
            self.accessTokenURL = accessTokenURL
            self.deviceCodeURL = deviceCodeURL
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.redirectURI = redirectURI
            self.scope = scope
            self.encodeHttpBody = encodeHttpBody
            self.customUserAgent = customUserAgent
            self.debug = debug
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
            clientSecret = try container.decodeIfPresent(String.self, forKey: .clientSecret)
            redirectURI = try container.decodeIfPresent(String.self, forKey: .redirectURI)
            scope = try container.decodeIfPresent([String].self, forKey: .scope)
            encodeHttpBody = try container.decodeIfPresent(Bool.self, forKey: .encodeHttpBody) ?? true
            customUserAgent = try container.decodeIfPresent(String.self, forKey: .customUserAgent)
            debug = try container.decodeIfPresent(Bool.self, forKey: .debug) ?? false
        }
    }
}
