//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoPasswordManager
import SudoKeyManager
import SudoUser
import SudoProfiles
import SudoEntitlements

class DefaultPasswordClientServiceTests: XCTestCase {

    var keyManager: SudoKeyManagerImpl!
    var service: DefaultPasswordClientService!
    var client: MyMockSudoSecureVaultClient!
    var userClient: MockSudoUserClient!
    var sudoProfilesClient: MockSudoProfilesClient!
    var entitlements: SudoEntitlementsClient!

    override func setUpWithError() throws {
        self.client = MyMockSudoSecureVaultClient()
        self.userClient = MockSudoUserClient()
        self.sudoProfilesClient = MockSudoProfilesClient()
        self.entitlements = MockSudoEntitlementsClient()

        self.service = DefaultPasswordClientService(client: self.client,
                                                    sudoUserClient: self.userClient,
                                                    sudoProfilesClient: self.sudoProfilesClient,
                                                    entitlementsClient: self.entitlements)
    }

    func testUserSubject() {
        // Returns nil if not set
        XCTAssertEqual(self.service.getUserSubject(), nil)

        // Returns expected value
        self.userClient.getSubjectReturn = "Foo"
        XCTAssertEqual(self.service.getUserSubject(), "Foo")

        // Returns expected value when changed
        self.userClient.getSubjectReturn = "Bar"
        XCTAssertEqual(self.service.getUserSubject(), "Bar")

        // Returns nil if error is returned.
        self.userClient.getSubjectError = NSError.some
        XCTAssertEqual(self.service.getUserSubject(), nil)
    }

    func testGetOwnershipProofSuccess() {
        let expectation = self.expectation(description: "")
        self.sudoProfilesClient.getOwnershipProofCompletionResult = .success(jwt: "Foo")

        self.service.getOwnershipProof(sudoId: "Foo") { (result) in
            expectation.fulfill()
            XCTAssertEqual(try? result.get(), "Foo")
            XCTAssertEqual(self.sudoProfilesClient.getOwnershipProofParameters?.sudo.id, "Foo")

        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetOwnershipProofFailure() {
        let expectation = self.expectation(description: "")
        self.sudoProfilesClient.getOwnershipProofCompletionResult = .failure(cause: NSError.some)
        self.service.getOwnershipProof(sudoId: "Foo") { (result) in
            XCTAssertNil(try? result.get())
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

}

class DefaultPasswordManagerKeyManagerTests: XCTestCase {

    var userClient: MockSudoUserClient!
    var keyManager: DefaultPasswordManagerKeyManager!

    override func setUpWithError() throws {
        self.userClient = MockSudoUserClient()
        self.keyManager = DefaultPasswordManagerKeyManager(userClient: self.userClient)
        try self.keyManager.removeAllKeys()
    }

    func testGenerateKeyDerivingKey() {
        do {
            let key = try self.keyManager.generateKeyDerivingKey()
            XCTAssertEqual(key.count, 128 >> 3)
        }
        catch {
            XCTFail("Generate key failed by throwing error: \(error)")
        }
    }

    func testSaveAndGetKDK() {
        self.userClient.getUserNameReturn = "Foo"
        do {
            let key = try self.keyManager.generateKeyDerivingKey()
            try self.keyManager.set(keyDerivingKey: key)
            let fetchedKey = try self.keyManager.getKeyDerivingKey()
            XCTAssertEqual(key, fetchedKey)
        }
        catch {
            XCTFail("test failed by throwing error: \(error)")
        }
    }

    func testEncryptedFields() {
        do {
            let testKey = try self.keyManager.generateKeyDerivingKey()
            let sentence = "I've got a lovely bunch of coconuts"
            let sentenceData = sentence.data(using: .utf8)!

            let encryptedSentence = try self.keyManager.encryptSecureField(data: sentenceData, usingKey: testKey)
            let decryptedSentence = try self.keyManager.decryptSecureField(data: encryptedSentence, usingKey: testKey)

            XCTAssertEqual(sentenceData, decryptedSentence)
            XCTAssertEqual(sentence, String(data: decryptedSentence, encoding: .utf8)!)
        }
        catch {
            XCTFail("test failed by throwing error: \(error)")
        }
    }

    func testEncryptedFieldsSingleCharacter() {
        do {
            let testKey = try self.keyManager.generateKeyDerivingKey()
            let sentence = "I"
            let sentenceData = sentence.data(using: .utf8)!

            let encryptedSentence = try self.keyManager.encryptSecureField(data: sentenceData, usingKey: testKey)
            let decryptedSentence = try self.keyManager.decryptSecureField(data: encryptedSentence, usingKey: testKey)

            XCTAssertEqual(sentenceData, decryptedSentence)
            XCTAssertEqual(sentence, String(data: decryptedSentence, encoding: .utf8)!)
        }
        catch {
            XCTFail("test failed by throwing error: \(error)")
        }
    }

    func testEncryptedFieldsEmptyString() {
        do {
            let testKey = try self.keyManager.generateKeyDerivingKey()
            let sentence = ""
            let sentenceData = sentence.data(using: .utf8)!

            let encryptedSentence = try self.keyManager.encryptSecureField(data: sentenceData, usingKey: testKey)
            let decryptedSentence = try self.keyManager.decryptSecureField(data: encryptedSentence, usingKey: testKey)

            XCTAssertEqual(sentenceData, decryptedSentence)
            XCTAssertEqual(sentence, String(data: decryptedSentence, encoding: .utf8)!)
        }
        catch {
            XCTFail("test failed by throwing error: \(error)")
        }
    }

    func testDecycryptFailsIVLengthToShort() {


        do {
            let testKey = try self.keyManager.generateKeyDerivingKey()
            let decryptedSentence = try? self.keyManager.decryptSecureField(data: "".data(using: .utf8)!, usingKey: testKey)
            XCTAssertNil(decryptedSentence)
        }
        catch {
            XCTFail("test failed by throwing error: \(error)")
        }
    }

    func testDecycryptSucceedsWithNoEncryptedData() {
        do {
            let testKey = try self.keyManager.generateKeyDerivingKey()
            let decryptedData = try keyManager.decryptSecureField(data: Data(repeating: 0xFF, count: 16), usingKey: testKey)
            let decryptedSentence = String(data: decryptedData, encoding: .utf8)
            XCTAssertEqual(decryptedSentence, "")
        }
        catch {
            XCTFail("test failed by throwing error: \(error)")
        }
    }
}

