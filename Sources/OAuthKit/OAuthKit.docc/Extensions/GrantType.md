# ``OAuthKit/OAuth/GrantType``

@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

> Important: For apps that don't have access to a web browser (like tvOS or watchOS), you'll need to start
an ``OAuth/authorize(provider:grantType:)`` flow with the ``deviceCode`` grant Type. See <doc:GettingStarted> for more details.

## Topics

### Associated Values

- ``OAuth/PKCE``
- ``OAuth/DeviceCode``
