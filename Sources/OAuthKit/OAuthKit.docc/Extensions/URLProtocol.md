# ``OAuthKit/OAuth/URLProtocol``
@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
The URLProtocol can be registered with any `URLSessionConfiguration` and will automatically inject `Authorization` headers into outbound HTTP URLRequests if patterns are matched. The following is an example of using the `OAuth.URLProtocol` with [GitHub](https://docs.github.com/en/rest).

```swift
import OAuthKit

// 1) The app registers the URLProtocol with the an session it uses to communicate with GitHub rest endpoints 
let configuration: URLSessionConfiguration = .ephemeral
configuration.protocolClasses = [OAuth.URLProtocl.self]
let urlSession: URLSession = .init(configuration: configuration)

// 2) Create a GitHub Provider that matches all rest endpoint patterns of `api.github.com` HTTP URLRequest.
let provider: OAuth.Provider = .init(
    id: "GitHub",
    authorizationURL: URL(string: "https://github.com/login/oauth/authorize"),
    accessTokenURL: URL(string: "https://github.com/login/oauth/access_token"),
    clientID: "CLIENT_ID",
    clientSecret: "CLIENT_SECRET",
    authorizationPattern: "api.github.com"
)

// 3) Authorize the Github Provider for an access token and once an authorization
// is received, the ``OAuth/Authorization/token`` will be added to the `OAuth.URLProtocol`
let oauth: OAuth = .init(providers: [provider])
oauth.authorize(provider: provider)

// 4) The app makes an API request to any GitHub REST endpoint with the URLSession and it will automatically include
// the necessary `Authorization: Bearer <<token>>` header in any outbound HTTP URLRequests to `api.github.com`.
let url: URL = .init(string: "https://api.github.com/orgs/{ORG}/repos")
let request = URLRequest(url: url)
let (data, response) = try await urlSession.data(for: request)

// Decode data from GitHub ...

```

- SeeAlso:
[Making Authenticated Requests](https://www.oauth.com/oauth2-servers/making-authenticated-requests/)
