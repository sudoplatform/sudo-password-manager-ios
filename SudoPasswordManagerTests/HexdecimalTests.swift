//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import SudoPasswordManager

class HexdecimalTests: XCTestCase {

    func convertToString() {
        XCTAssertEqual(Data.init([0xF]).hexString, "F")
        XCTAssertEqual(Data.init([0xFF]).hexString, "FF")

        XCTAssertEqual(Data.init([0x1]).hexString, "1")
        XCTAssertEqual(Data.init([0x11]).hexString, "11")
    }

    func testEvenStringToData() {
        XCTAssertEqual(Data(hexdecimalString: "FF"), Data([0xFF]))
    }

    func testOddStringToData() {
        XCTAssertEqual(Data(hexdecimalString: "F"), Data([0xF]))
    }

    func testZero() {
        XCTAssertEqual(Data(hexdecimalString: "0"), Data([0x0]))
    }

    func testMultipleBytes() {
        XCTAssertEqual(Data(hexdecimalString: "FFFFFFFF"), Data([0xFF, 0xFF, 0xFF, 0xFF]))
    }

    func testInvalidCharacters() {
        XCTAssertEqual(Data(hexdecimalString: "FFG"), nil)
        XCTAssertEqual(Data.init(hexdecimalString: "FF")?.count, 1)
    }
}
