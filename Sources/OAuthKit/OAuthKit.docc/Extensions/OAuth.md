# ``OAuthKit/OAuth``
@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Topics

### Creating an Observable OAuth

- ``init(_:options:)``
- ``init(providers:options:)``

### Starting an authorization flow

- ``authorize(provider:grantType:)``
- ``OAuth/GrantType``

### OAuth State Tracking

- ``state``
- ``providers``
