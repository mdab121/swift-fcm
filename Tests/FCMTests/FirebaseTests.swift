// (c) 2017 Kajetan Michal Dabrowski
// This code is licensed under MIT license (see LICENSE for details)

import XCTest
import Foundation
@testable import FCM

class FirebaseTests: XCTestCase {

	let exampleServerKey = ServerKey("this-is-an-invalid-server-key")
	let exampleToken = DeviceToken("this-is-an-invalid-token")
	let message = Message(payload: Payload(message: "What's up!"))

	var sut: Firebase!

	override func setUp() {
		super.setUp()
		sut = Firebase(serverKey: exampleServerKey)
	}

	override func tearDown() {
		sut = nil
		super.tearDown()
	}

	/// This is not exactly a unit test, since it accesses the internet, or at least tries to use curl.
	/// I'm not checking any results (it'll still pass if there is no internet connection). It's mostly useful to see if all the api including curl are present on the system

	func testSimpleSending() throws {
		let expectation = self.expectation(description: "FirebaseQuery")
		var capturedResponse: FirebaseResponse?

		try sut.send(message: message, to: exampleToken) { response in
			capturedResponse = response
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5) { error in
			XCTAssertNotNil(capturedResponse)
			XCTAssertNotNil(capturedResponse?.error)
			XCTAssertFalse(capturedResponse!.success)
		}
	}

	static var allTests : [(String, (FirebaseTests) -> () throws -> Void)] {
		return [
			("testSimpleSending", testSimpleSending)
		]
	}
}
