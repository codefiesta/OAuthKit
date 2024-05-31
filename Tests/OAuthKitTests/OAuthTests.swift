@testable import OAuthKit
import XCTest

final class OAuthTests: XCTestCase {

    /// Tests the init method using a custom bundle.
    func testInit() throws {
        let oauth: OAuth = .init(.module)
        let providers = oauth.providers
        XCTAssertGreaterThan(providers.count, 0)
    }

    /// Tests the custom date extension operator.
    func testDateExtensions() {
        let expiresIn = 60
        let now = Date.now
        let issued = now.addingTimeInterval(-TimeInterval(expiresIn * 10)) // 10 minutes ago
        let expiration = issued.addingTimeInterval(TimeInterval(expiresIn))
        let timeInterval = expiration - Date.now
        XCTAssertLessThan(timeInterval, 0)
    }
}
