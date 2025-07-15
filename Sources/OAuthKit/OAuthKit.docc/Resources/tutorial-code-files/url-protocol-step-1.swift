// 1) Configure the URLSession that your app will use to make API requests with Github
let configuration: URLSessionConfiguration = .ephemeral
configuration.protocolClasses = [OAuth.URLProtocol.self]
let urlSession: URLSession = .init(configuration: configuration)
