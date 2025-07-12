# ``OAuthKit/OAuth/Token``

@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
A `Token` is the holder of an ``accessToken`` that can be used in an `URLRequest` to provide credentials for authentication, allowing access to protected resources.

```swift
/// Adds a header field of 'Authorization: Bearer <<access_token>>'
let value = "\(token.type) \(token.accessToken)"
var request: URLRequest = .init(url: url)
request.addValue(value, forHTTPHeaderField: "Authorization")
```

- SeeAlso:
[Access Token Response](https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/)

## Topics

### Essentials

- ``OAuth/Authorization``
- ``Foundation/URLRequest/addAuthorization(auth:)``
