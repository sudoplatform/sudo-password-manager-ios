//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoPasswordManager

class PasswordGeneratorTests: XCTestCase {

    let uppercaseSet = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ")
    let lowercaseSet = CharacterSet(charactersIn: "abcdefghijkmnpqrstuvwxyz")
    let numbersSet = CharacterSet(charactersIn: "23456789")
    let symbolsSet = CharacterSet(charactersIn: "!?@*._-")

    func testDefaultParameters() {
        let password = generatePassword()
        // check password length
        XCTAssertEqual(password.count, 20)
        // check for at least one of each character type
        XCTAssertNotNil(password.rangeOfCharacter(from: uppercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: lowercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: numbersSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: symbolsSet))
    }

    func testSetLength() {
        let password = generatePassword(length: 25)
        XCTAssertEqual(password.count, 25)
    }

    func testMinLength() {
        let password = generatePassword(length: 0)
        XCTAssertEqual(password.count, 6)
    }

    func testExcludeUppercase() {
        let password = generatePassword(allowUppercase: false)
        XCTAssertNil(password.rangeOfCharacter(from: uppercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: lowercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: numbersSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: symbolsSet))
    }

    func testExcludeLowercase() {
        let password = generatePassword(allowLowercase: false)
        XCTAssertNotNil(password.rangeOfCharacter(from: uppercaseSet))
        XCTAssertNil(password.rangeOfCharacter(from: lowercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: numbersSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: symbolsSet))
    }

    func testExcludeNumbers() {
        let password = generatePassword(allowNumbers: false)
        XCTAssertNotNil(password.rangeOfCharacter(from: uppercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: lowercaseSet))
        XCTAssertNil(password.rangeOfCharacter(from: numbersSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: symbolsSet))
    }

    func testExcludeSymbols() {
        let password = generatePassword(allowSymbols: false)
        XCTAssertNotNil(password.rangeOfCharacter(from: uppercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: lowercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: numbersSet))
        XCTAssertNil(password.rangeOfCharacter(from: symbolsSet))
    }

    func testExcludeAll() {
        // excluding all should enable all
        let password = generatePassword(length: 20, allowUppercase: false, allowLowercase: false, allowNumbers: false, allowSymbols: false)
        XCTAssertNotNil(password.rangeOfCharacter(from: uppercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: lowercaseSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: numbersSet))
        XCTAssertNotNil(password.rangeOfCharacter(from: symbolsSet))
    }

    func testNoAmbiguousCharacters() {
        // check multiple passwords to ensure the ambiguous characters are never included
        for _ in 0...20 {
            let password = generatePassword(length: 50)
            let ambiguousCharacters = CharacterSet(charactersIn: "oO0lI1")
            XCTAssertNil(password.rangeOfCharacter(from: ambiguousCharacters))
        }
    }

    func testVeryWeakPassword() {
        let password = "mypassword"
        let strength = calculateStrength(of: password)
        XCTAssertEqual(strength, .veryWeak)
    }

    func testWeakPassword() {
        let password = "MyWeakPassword123!"
        let strength = calculateStrength(of: password)
        XCTAssertEqual(strength, .weak)
    }

    func testModeratePassword() {
        let password = "MyModeratePassword123!?"
        let strength = calculateStrength(of: password)
        XCTAssertEqual(strength, .moderate)
    }

    func testStrongPassword() {
        let password = "#$MyStrongPassword123!?"
        let strength = calculateStrength(of: password)
        XCTAssertEqual(strength, .strong)
    }

    func testVeryStrongPassword() {
        let password = "#$MyVeryStrongPassword123!?"
        let strength = calculateStrength(of: password)
        XCTAssertEqual(strength, .veryStrong)
    }
}
