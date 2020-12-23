//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoPasswordManager
class SecretCodeTests: XCTestCase {

    func testGenerateSecretCodeTooShort() {
        XCTAssertNil(formatSecretCode(string: String(repeating: "F", count: 36)))
    }

    func testGenerateSecretCodeTooLong() {
        XCTAssertNil(formatSecretCode(string: String(repeating: "F", count: 38)))
    }

    func testGenerateSecretCodeJustRight() {
        XCTAssertEqual(formatSecretCode(string: String(repeating: "F", count: 37)), "FFFFF-FFFFFF-FFFFF-FFFFF-FFFFF-FFFFF-FFFFFF")
    }
}


