// 2) Configure a Provider that matches all patterns of `api.github.com`
let provider: OAuth.Provider = .init(
    id: "GitHub",
    authorizationURL: URL(string: "https://github.com/login/oauth/authorize"),
    accessTokenURL: URL(string: "https://github.com/login/oauth/access_token"),
    clientID: "CLIENT_ID",
    clientSecret: "CLIENT_SECRET",
    authorizationPattern: "api.github.com"
)

// 3) Authorize the GitHub Provider to start an OAuth flow
let oauth: OAuth = .init(providers: [provider])
oauth.authorize(provider: provider)
