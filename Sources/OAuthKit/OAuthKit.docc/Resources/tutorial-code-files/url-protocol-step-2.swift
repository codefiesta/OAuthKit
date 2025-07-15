// 1) Configure the URLSession that your app will use to make API requests with Github
let configuration: URLSessionConfiguration = .ephemeral
configuration.protocolClasses = [OAuth.URLProtocol.self]
let urlSession: URLSession = .init(configuration: configuration)

// 2) Configure a Provider that matches all patterns of `api.github.com`
let provider: OAuth.Provider = .init(
    id: "GitHub",
    authorizationURL: URL(string: "https://github.com/login/oauth/authorize"),
    accessTokenURL: URL(string: "https://github.com/login/oauth/access_token"),
    clientID: "CLIENT_ID",
    clientSecret: "CLIENT_SECRET",
    authorizationPattern: "api.github.com"
)
