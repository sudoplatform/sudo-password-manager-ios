//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoPasswordManager

class PasswordManagerClientErrorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Make sure the values passed to init yields the correct object
    func testInit() throws {

        // Test init with type
        let initWithType = PasswordManagerError(type: .notAuthorized)
        XCTAssertEqual(initWithType.type, PasswordManagerError.ErrorType.notAuthorized)
        XCTAssertNil(initWithType.underlyingError)
        XCTAssertNil(initWithType.userInfo)

        // Test init with type and underlying error
        let randomError = NSError(domain: "", code: 0, userInfo: nil)
        let initWithTypeAndUnderlyingError = PasswordManagerError(type: .notAuthorized, underlyingError: randomError)
        XCTAssertEqual(initWithTypeAndUnderlyingError.type, PasswordManagerError.ErrorType.notAuthorized)
        XCTAssertEqual(String(describing: initWithTypeAndUnderlyingError.underlyingError!), String(describing: randomError))
        XCTAssertNil(initWithType.userInfo)

        // Test init with type, underlying error, and user info
        let userInfo = ["Foo": "Bar"]
        let initWithTypeAndUnderlyingErrorAndUserInfo = PasswordManagerError(type: .notAuthorized, underlyingError: randomError, userInfo: userInfo)
        XCTAssertEqual(initWithTypeAndUnderlyingError.type, PasswordManagerError.ErrorType.notAuthorized)
        XCTAssertEqual(String(describing: initWithTypeAndUnderlyingError.underlyingError!), String(describing: randomError))
        XCTAssertEqual(String(describing: initWithTypeAndUnderlyingErrorAndUserInfo.userInfo!), String(describing: userInfo))
    }

    /// Test that the error description is correct.  This should fail if someone adds a new error case but doesn't update
    /// the error description, or doesn't add a test for it.
    func testErrorDescription() {
        for type in PasswordManagerError.ErrorType.allCases {
            let error = PasswordManagerError(type: type)

            switch type {
            case .invalidPasswordOrMissingSecretCode:
                XCTAssertEqual(error.errorDescription!, "The password is invalid or no secret code exists locally")
            case .invalidVault:
                XCTAssertEqual(error.errorDescription!, "The vault data retrieved is invalid. This indicates the vault is corrupt or is encrypted using a key that's not known to the client")
            case .notAuthorized:
                XCTAssertEqual(error.errorDescription!, "The user is not authorized to perform the requested operation. This maybe due to specifying the wrong key deriving key or password")
            case .unknown:
                XCTAssertEqual(error.errorDescription!, "An unknown error occurred")
            case .vaultLocked:
                XCTAssertEqual(error.errorDescription!, "The vault is locked and must be unlocked to proceed")
            case .versionMismatch:
                XCTAssertEqual(error.errorDescription!, "The version of the vault that's being updated or deleted does not match the version stored in the backed. It is likely that another client updated the vault first so the caller should reconcile the changes before attempting to update or delete the vault")
            case .invalidFormat:
                XCTAssertEqual(error.errorDescription!, "The format of the input was invalid")
            case .internal:
                XCTAssertEqual(error.errorDescription!, "An internal error occured. This is most likely due to an internal framework, e.g unable to generate encryption keys.")
            case .security:
                XCTAssertEqual(error.errorDescription!, "There was a problem using the system Security framework")
            case .secureVaultService:
                XCTAssertEqual(error.errorDescription!, "The Sudo Secure Vault service returned an error during an operation.")
            }
        }
    }
}
