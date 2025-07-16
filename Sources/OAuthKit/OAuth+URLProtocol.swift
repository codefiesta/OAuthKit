//
//  OAuth+URLProtocol.swift
//  OAuthKit
//
//  Created by Kevin McKee
//

import Foundation

extension OAuth {

    /// A custom `URLProtocol` that can be registered with any `URLSessionConfiguration` that will automatically inject
    /// `Authorization: Bearer <<token>>` headers into outbound HTTP URLRequests based on ``Provider/authorizationPattern``.
    public class URLProtocol: Foundation.URLProtocol, URLSessionDataDelegate, @unchecked Sendable {

        private var session: URLSession?
        private var sessionDataTask: URLSessionDataTask?

        /// The lock that provides manual synchronization around access to authorization tokens.
        private static let lock: NSLock = .init()
        nonisolated(unsafe) private static var _authorizations: [OAuth.Provider: OAuth.Authorization] = .init()

        static var authorizations: [OAuth.Provider: OAuth.Authorization] {
            get { lock.withLock { _authorizations } }
            set { lock.withLock { _authorizations = newValue } }
        }

        /// Common Initializer.
        /// - Parameters:
        ///   - request: the url requesy
        ///   - cachedResponse: the cached response
        ///   - client: the client
        override public init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
            if session == nil {
                session = .init(configuration: .default, delegate: self, delegateQueue: nil)
            }
        }

        /// Adds an authorization for the given provider that can be used inject `Authorization: Bearer <<token>>` headers into a request.
        /// - Parameters:
        ///   - authorization: the authorization issued by the provider
        ///   - provider: the provider
        @MainActor
        public class func addAuthorization(_ authorization: OAuth.Authorization, for provider: OAuth.Provider) {
            guard let _ = provider.authorizationPattern else { return }
            authorizations[provider] = authorization
        }

        /// Removes authorizations for the specified provider.
        /// - Parameter provider: the provider to remove authorization for
        @MainActor
        public class func removeAuthorization(for provider: OAuth.Provider) {
            authorizations.removeValue(forKey: provider)
        }

        /// Clears all authorizations out of the protocol.
        @MainActor
        public class func clear() {
            authorizations.removeAll()
        }

        /// Determines whether this protocol can handle the given request.
        /// - Parameter request: the request to handle
        /// - Returns: true if this protocl can handle the given request.
        override public class func canInit(with request: URLRequest) -> Bool {
            // Remove any expired authorizations
            let expiredEntries = authorizations.filter{ $0.value.isExpired }
            for expired in expiredEntries {
                authorizations.removeValue(forKey: expired.key)
            }
            guard let url = request.url, authorizations.isNotEmpty else { return false }
            for (provider, _) in authorizations {
                guard let pattern = provider.authorizationPattern else { continue }
                if url.absoluteString.range(of: pattern, options: .regularExpression) != nil {
                    return true
                }
            }
            return false
        }

        /// Determines whether this protocol can handle the given task.
        /// - Parameter task: the task to handle
        /// - Returns: true if this protocl can handle the given task.
        override public class func canInit(with task: URLSessionTask) -> Bool {
            guard let request = task.originalRequest else { return false }
            return canInit(with: request)
        }

        /// If an authorized provider matches the given request, then this method returns a canonical version
        /// of the given request with an additional `Authorization: Bearer <<token>>` header field.
        /// - Parameter request: the request
        /// - Returns: the canonical version of the given request.
        override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
            guard let url = request.url, authorizations.isNotEmpty else { return request }
            for (provider, auth) in authorizations {
                guard let pattern = provider.authorizationPattern else { continue }
                if url.absoluteString.range(of: pattern, options: .regularExpression) != nil {
                    var canonicalRequest = request
                    canonicalRequest.addAuthorization(auth: auth)
                    return canonicalRequest
                }
            }
            return request
        }

        /// Starts the loading of the current request.
        override public func startLoading() {
            sessionDataTask = session?.dataTask(with: request)
            sessionDataTask?.resume()
        }

        /// Stops the loading of the current request.
        override public func stopLoading() {
            sessionDataTask?.cancel()
        }

        /// Called when data is available to consume.
        /// - Parameters:
        ///   - session: the url session
        ///   - dataTask: the data task
        ///   - data: the data to consume
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let response = dataTask.response else { return }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }

        /// Called when task is done loading data.
        /// - Parameters:
        ///   - session: the url session
        ///   - task: the session task
        ///   - error: any error that may have occurred
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
            if let error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
            completionHandler(request)
        }

        public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
            guard let error = error else { return }
            client?.urlProtocol(self, didFailWithError: error)
        }

        public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}


