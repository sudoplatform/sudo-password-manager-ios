//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoPasswordManager

class MasterPasswordTransformerTests: XCTestCase {

    func testWhitespaceCharactersAreTrimmed() {
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: " \n \t hello \n \t ").standardize(), "hello")
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: " hello ").standardize(), "hello")
    }

    func testWhitespaceRemainsInBody() {
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: " hell no ").standardize(), "hell no")
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: " hell\tno ").standardize(), "hell\tno")
    }

    func testNFKDNormalization() {
        //'\u{212B}', // 'Å' ANGSTROM SIGN
        //'\u{00C5}', // 'Å' LATIN CAPITAL LETTER A WITH RING ABOVE
        //'\u{0041}\u{030A}', // 'A' LATIN CAPITAL LETTER A + '°' COMBINING RING ABOVE
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: "hello\u{212B}").standardize(), "helloÅ")
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: "hello\u{00C5}").standardize(), "helloÅ")
        XCTAssertEqual(MasterPasswordTransformer(userProvidedValue: "hello\u{0041}\u{030A}").standardize(), "helloÅ")
    }
}
