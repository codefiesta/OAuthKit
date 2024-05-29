import XCTest
@testable import OAuthKit

final class OAuthTests: XCTestCase {

    /// Tests the init method using a custom bundle.
    func testInit() throws {
        let oauth: OAuth = .init(.module)
        let providers = oauth.providers
        XCTAssertGreaterThan(providers.count, 0)
    }
}
