//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoPasswordManager

class SecretCodeTests: XCTestCase {

    func test_generateSecretCode_tooShort() {
        XCTAssertNil(formatSecretCode(string: String(repeating: "F", count: 36)))
    }

    func test_generateSecretCode_tooLong() {
        XCTAssertNil(formatSecretCode(string: String(repeating: "F", count: 38)))
    }

    func test_generateSecretCode_success() {
        XCTAssertEqual(formatSecretCode(string: String(repeating: "F", count: 37)), "FFFFF-FFFFFF-FFFFF-FFFFF-FFFFF-FFFFF-FFFFFF")
    }

    func test_parseSecretCode_withSpaces() {
        let spacedKDK = "ab cde fgh ijk lmnop qrs tu vwxyz 123 456 "
        let regularKDK = "abcdefghijklmnopqrstuvwxyz123456"

        let spacedParsed = parseSecretCode(string: spacedKDK)
        let regularParsed = parseSecretCode(string: regularKDK)
        XCTAssertEqual(spacedParsed, regularParsed)
    }

    func test_parseSecretCode_withDashes() {
        let dashedKDK = "abcde-fghijk-lmnop-qrstu-vwxyz-123456"
        let regularKDK = "abcdefghijklmnopqrstuvwxyz123456"

        let dashedParsed = parseSecretCode(string: dashedKDK)
        let regularParsed = parseSecretCode(string: regularKDK)
        XCTAssertEqual(dashedParsed, regularParsed)
    }
}


