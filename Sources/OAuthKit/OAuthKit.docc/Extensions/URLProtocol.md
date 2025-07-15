# ``OAuthKit/OAuth/URLProtocol``
@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
The URLProtocol can be registered with any `URLSessionConfiguration` and will automatically inject `Authorization` headers into outbound HTTP URLRequests if patterns are matched.

### Tutorials

@Links(visualStyle: list) {
    - <doc:URLProtocol>
}

- SeeAlso:
[Making Authenticated Requests](https://www.oauth.com/oauth2-servers/making-authenticated-requests/)
