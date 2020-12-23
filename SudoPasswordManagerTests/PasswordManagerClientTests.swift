//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoPasswordManager
import SudoKeyManager
import SudoUser
import SudoSecureVault
import SudoEntitlements
import SudoProfiles

class PasswordManagerClientTests: XCTestCase {

    var secureVaultClient: MyMockSudoSecureVaultClient!
    var service: PasswordClientServiceMock!
    var client: DefaultPasswordManagerClient!
    var userClientMock: MockSudoUserClient!
    var keyManager: MockPasswordManagerKeyManager!
    var entitlements: MockSudoEntitlementsClient!
    var sudoProfilesclient: MockSudoProfilesClient!
    
    var secretCode: String = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"

    override func setUpWithError() throws {
        self.secureVaultClient = MyMockSudoSecureVaultClient()
        self.userClientMock = MockSudoUserClient()

        self.keyManager = MockPasswordManagerKeyManager()

        self.entitlements = MockSudoEntitlementsClient()

        self.sudoProfilesclient = MockSudoProfilesClient()

        self.service = PasswordClientServiceMock(client: self.secureVaultClient, sudoUserClient: self.userClientMock, keyManager: keyManager, entitlementsClient: self.entitlements, sudoProfilesClient: self.sudoProfilesclient)
        self.client = DefaultPasswordManagerClient(service: self.service)

        self.service.userSubject = UUID().uuidString
    }

    func useKeychain() {
        let km = DefaultPasswordManagerKeyManager(userClient: self.userClientMock)
        try? km.removeAllKeys()
        self.service.keyManager = km
    }

    func setUsername(_ name: String) {
        self.userClientMock.getUserNameReturn = name
    }

    /// Tests all valid combinations of success/failure that `getRegistrationStatus` returns.
    func testGetRegistrationStatus() throws {
        self.secureVaultClient.isRegisteredResult = .success(false)

        // Test client not registered
        XCTAssertEqual(try? awaitResult { self.client.getRegistrationStatus(completion: $0) }.get(), .notRegistered)

        // Test client is registered but no secret key found
        self.secureVaultClient.isRegisteredResult = .success(true)
        XCTAssertEqual(try? awaitResult { self.client.getRegistrationStatus(completion: $0) }.get(), .missingSecretCode)

        // Test client is registered and secret key found
        self.secureVaultClient.isRegisteredResult = .success(true)
        self.keyManager.getKeyDerivingKeyResult = Data()
        XCTAssertEqual(try? awaitResult { self.client.getRegistrationStatus(completion: $0) }.get(), .registered)

        // Test client is registered and get secret key returns error
        self.secureVaultClient.isRegisteredResult = .success(true)
        self.keyManager.getKeyDerivingKeyError = NSError.some
        if case .failure(let registrationGetKeyError) = awaitResult({ self.client.getRegistrationStatus(completion: $0) }) {
            XCTAssertEqual((registrationGetKeyError as! PasswordManagerError).type, PasswordManagerError.ErrorType.security)
        }
        else {
            XCTFail("Expected getRegistrationStatus to return failure, but returned success instead.")
        }

        // Test that errors returned by the secure vault service are propagated.
        self.secureVaultClient.isRegisteredResult = .failure(NSError.some)
        XCTAssertThrowsError(try awaitResult({ self.client.getRegistrationStatus(completion: $0) }).get())
    }
    /// Tests that the key generated during create is saved.
    /// Also tests success if the client returns success
    func testKeyDerivingKeySavedDuringRegisterSuccess() {
        let expectation = self.expectation(description: "")
        let masterPassword = "Password"

        self.secureVaultClient.registerResult = .success("")

        let key = Data(repeating: 1, count: 8)
        self.keyManager.generateKeyDerivingKeyResult = key
        self.client.register(masterPassword: masterPassword) { (result) in
            XCTAssertEqual(self.keyManager.setKeyDerivingKeyParamKey, key)
            XCTAssertTrue(self.keyManager.setKeyDerivingKeyCalled)
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should not have failed")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    /// Tests that the key generated during create is saved even if registration appears to fail.
    /// Also ensures registration failure from client is propagated up.
    func testKeyDerivingKeySavedDuringRegisterFailure() {
        func testKeyDerivingKeyCreatedDuringRegisterSuccess() {
            let expectation = self.expectation(description: "")
            let masterPassword = "Password"
            self.secureVaultClient.registerResult = .failure(NSError.some)
            let key = KeyDerivingKey.withUUID
            self.keyManager.generateKeyDerivingKeyResult = key
            self.client.register(masterPassword: masterPassword) { (result) in
                XCTAssertEqual(self.keyManager.setKeyDerivingKeyParamKey, key)
                XCTAssertTrue(self.keyManager.setKeyDerivingKeyCalled)
                switch result {
                case .success:
                    XCTFail("Should not have succeeded")
                case .failure:
                    break
                }

                // Test the correct key and password were passed to regsiter
                guard let registerParamKey = self.secureVaultClient.registerParamKey,
                    let registerParamPassword = self.secureVaultClient.registerParamPassword else {
                    XCTFail("Missing registartion parameters passed to secure vault client")
                    return
                }

                XCTAssertEqual(registerParamKey, key)
                XCTAssertEqual(registerParamPassword, masterPassword.data(using: .utf8))

                expectation.fulfill()
            }
            self.waitForExpectations(timeout: 5, handler: nil)
        }
    }

    func testKdkGenerateFailureIsReturned() {
        // set register to return success
        self.secureVaultClient.registerResult = .success("")
        // set service to fail key generating key deriving key
        let error = NSError.some
        self.keyManager.generateKeyDerivingKeyError = error
        let result = awaitResult({self.client.register(masterPassword: "", completion: $0)})
        XCTAssertThrowsError(try result.get(), "") { (resultError) in
            guard let internalError = (resultError as? PasswordManagerError) else { XCTFail(); return }

            XCTAssertEqual(internalError.type, PasswordManagerError.ErrorType.secureVaultService)
            XCTAssertEqual((internalError.underlyingError as NSError?), error)
        }
    }

    func testSetKeyDerivingKeyFrailsOnRegistration() {
        // set register to return success
        self.secureVaultClient.registerResult = .success("")
        self.keyManager.generateKeyDerivingKeyResult = KeyDerivingKey.withUUID
        // set service to fail to save key generating key
        let error = NSError.some
        self.keyManager.setKeyDerivingKeyError = error
        let result = awaitResult({self.client.register(masterPassword: "", completion: $0)})
        XCTAssertThrowsError(try result.get(), "") { (resultError) in
            guard let internalError = (resultError as? PasswordManagerError) else { XCTFail(); return }

            XCTAssertEqual(internalError.type, PasswordManagerError.ErrorType.secureVaultService)
            XCTAssertEqual((internalError.underlyingError as NSError?), error)
        }
    }

    // MARK: Lock/Unlock

    func testVaultUnlockFailsMissingSecretCode() {
        XCTAssertTrue(self.client.isLocked())

        let result = awaitResult({self.client.unlock(masterPassword: "Foo", secretCode: nil, completion: $0)})
        XCTAssertThrowsError(try result.get(), "") { (resultError) in
            XCTAssertEqual((resultError as? PasswordManagerError)?.type, PasswordManagerError.ErrorType.invalidPasswordOrMissingSecretCode)
        }
    }

    func testVaultUnlockSucceedsWithCachedKDK() {
        XCTAssertTrue(self.client.isLocked())

        self.keyManager.getKeyDerivingKeyResult = KeyDerivingKey.withUUID

        let result = awaitResult({self.client.unlock(masterPassword: "Foo", secretCode: nil, completion: $0)})
        XCTAssertNoThrow(try result.get())
    }

    func testVaultUnlockSucceedsWithProvidedSecretKey() {
        XCTAssertTrue(self.client.isLocked())

        let result = awaitResult({self.client.unlock(masterPassword: "Foo", secretCode: self.secretCode, completion: $0)})
        XCTAssertNoThrow(try result.get())

        guard let addedKey = self.keyManager.setKeyDerivingKeyParamKey else {
            XCTFail()
            return
        }

        XCTAssertEqual(addedKey.hexString, self.secretCode)
    }

    func testVaultUnlockSucceedsWithCachedAndProvidedKDK() {
        XCTAssertTrue(self.client.isLocked())

        self.keyManager.getKeyDerivingKeyResult = KeyDerivingKey.withUUID
        let result = awaitResult({self.client.unlock(masterPassword: "Foo", secretCode: "Bar", completion: $0)})
        XCTAssertNoThrow(try result.get())
    }

    func testUnlockFailsIfListFails() {
        XCTAssertTrue(self.client.isLocked())

        self.keyManager.getKeyDerivingKeyResult = KeyDerivingKey.withUUID

        self.secureVaultClient.listVaultsResult = .failure(SudoSecureVaultClientError.notAuthorized)

        let result = awaitResult({self.client.unlock(masterPassword: "Foo", secretCode: nil, completion: $0)})
        XCTAssertThrowsError(try result.get(), "") { (resultError) in
            XCTAssertEqual((resultError as? PasswordManagerError)?.type, PasswordManagerError.ErrorType.secureVaultService)
            XCTAssertEqual((resultError as? PasswordManagerError)?.underlyingError?.localizedDescription, SudoSecureVaultClientError.notAuthorized.localizedDescription)
        }
    }

    func testVaultLocksWhenUserChanges() {
        self.useKeychain()
        self.setUsername("Foo")

        XCTAssertEqual(self.client.isLocked(), true)
        self.unlockVault()
        XCTAssertEqual(self.client.isLocked(), false)
        self.userClientMock.getUserNameReturn = "E.T."
        XCTAssertEqual(self.client.isLocked(), true)
    }

    // MARK: CRUD tests

    private func unlockVault() {
        let result = awaitResult({self.client.unlock(masterPassword: "Foo", secretCode: self.secretCode, completion: $0)})
        XCTAssertNoThrow(try result.get())
    }

    func testCreateVaultFailsIfLocked() {
        XCTAssertTrue(self.client.isLocked())

        let createResult = awaitResult({self.client.createVault(sudoId: "foo", completion: $0)})
        XCTAssertThrowsError(try createResult.get()) { (resultError) in
            XCTAssertTrue(isError(resultError, ofType: .vaultLocked))
        }
    }

    func testCreateVaultSucceeds() {
        self.useKeychain()
        self.setUsername("Foo")

        XCTAssertTrue(self.client.isLocked())
        self.unlockVault()

        // Put some data into the secure vault client mock as the data that will be returned
        let creationDate = Date()
        let vaultMetaData = VaultMetadata(id: "1", owner: "", version: 0, blobFormat: "foo", createdAt: creationDate, updatedAt: creationDate, owners: [])
        self.secureVaultClient.createVaultResult = .success(vaultMetaData)

        let ownershipProof = "This city is killing me"
        self.service.getOwnershipProofResult = .success(ownershipProof)

        // Create the vault, make sure it doesn't throw any errors on creation
        let createResult = awaitResult({self.client.createVault(sudoId: ownershipProof, completion: $0)})
        XCTAssertNoThrow(try createResult.get())
        guard let vault = try? createResult.get() else { return }

        // Check that the vault data we get back from the call is the same data that the secure vault client will return
        XCTAssertEqual(vault.id, vaultMetaData.id)
        XCTAssertEqual(vault.createdAt, vaultMetaData.createdAt)
        XCTAssertEqual(vault.updatedAt, vaultMetaData.updatedAt)

        guard let blobFormatParam = self.secureVaultClient.createVaultParamBlobFormat,
              let blobParam = self.secureVaultClient.createVaultParamBlob,
              let ownershipProofParam = self.secureVaultClient.createVaultParamOwnershipProof else {
            XCTFail(); return
        }

        // Make sure the vault data we passed to the `create` call is the most recent schema version.
        XCTAssertEqual(blobFormatParam, VaultSchema.latest.rawValue)

        guard let _ = try? VaultSchema.CurrentModelSchema.Decoder().decode(data: blobParam) else { XCTFail(); return }

        // Check the ownership proof to make sure it made it's way up.
        XCTAssertEqual(ownershipProofParam, ownershipProof)
    }

    func testCreateFailsOnErrorFromSecureVaultClient() {
        self.useKeychain()
        self.setUsername("Foo")

        XCTAssertTrue(self.client.isLocked())
        self.unlockVault()

        let createVaultError = NSError.some
        self.secureVaultClient.createVaultResult = .failure(createVaultError)

        let createResult = awaitResult({self.client.createVault(sudoId: "Not this time", completion: $0)})

        XCTAssertThrowsError(try createResult.get()) { (resultError) in
            XCTAssertEqual(resultError as NSError, createVaultError)
        }
    }

    func testCreatedVaultCanBeFetched() {
        self.useKeychain()
        self.setUsername("Foo")

        XCTAssertTrue(self.client.isLocked())
        self.unlockVault()
        XCTAssertFalse(self.client.isLocked())

        // Put some data into the secure vault client mock as the data that will be returned
        let vaultID = "Golden Wings"
        let creationDate = Date()
        let vaultMetaData = VaultMetadata(id: vaultID, owner: "", version: 0, blobFormat: "foo", createdAt: creationDate, updatedAt: creationDate, owners: [])
        self.secureVaultClient.createVaultResult = .success(vaultMetaData)

        let ownershipProof = "This city is killing me"

        // Create the vault
        _ = awaitResult({self.client.createVault(sudoId: ownershipProof, completion: $0)})

        // Make sure that vaults recently created are avilable now
        let fetchResult = awaitResult({self.client.getVault(withId: vaultID, completion: $0) })
        guard case .success(let possibleVault) = fetchResult else {
            XCTFail(); return
        }

        // We can now check the vault is what we expect
        XCTAssertNotNil(possibleVault); guard let realVault = possibleVault else { return }
        XCTAssertEqual(realVault.id, vaultID)
    }

    // MARK: Get tests

    func testGetFailsIfLocked() {
        XCTAssertTrue(self.client.isLocked())
        let createResult = awaitResult({ self.client.getVault(withId: "", completion: $0) })
        XCTAssertThrowsError(try createResult.get()) { (resultError) in
            XCTAssertTrue(isError(resultError, ofType: .vaultLocked))
        }
    }

    func testGetVaultNoResult() {
        self.useKeychain()
        self.setUsername("Foo")

        self.unlockVault()

        // Look for a vault that doesn't exist
        let result = awaitResult({ self.client.getVault(withId: "Odd look", completion: $0)})

        // First checks for errors, second makes sure result is nil
        XCTAssertNoThrow(try result.get())
        XCTAssertNil(try? result.get())
    }

    func testGetVaultSuccess() {
        self.useKeychain()
        self.setUsername("Foo")

        self.unlockVault()

        // To test vaults exist, we need to populate the secure vault client with some vaults
        let aSecureVault = Vault(id: "Walk on the while side", owner: "", version: 1, blobFormat: "JSON", createdAt: Date(), updatedAt: Date(), owners: [], blob: Data())
        self.secureVaultClient.listVaultsResult = .success([aSecureVault])

        // Look for a vault that doesn't exist
        let result = awaitResult({ self.client.getVault(withId: aSecureVault.id, completion: $0)})

        // Get the vault from the result
        XCTAssertNoThrow(try result.get())
        guard let vault = try? result.get() else { return }

        XCTAssertEqual(vault.id, aSecureVault.id)
        XCTAssertEqual(vault.createdAt, aSecureVault.createdAt)
        XCTAssertEqual(vault.updatedAt, aSecureVault.updatedAt)
    }

    func testDeleteVault() {
        _ = self.populateServiceWithKnownVault()
        self.unlockVault()

        let listResult = awaitResult({ self.client.listVaults(completion: $0)})
        guard let vault = try? listResult.get().first else { return }

        let deleteResult = awaitResult({ self.client.deleteVault(withId: vault.id, completion: $0)})
        XCTAssertNoThrow(try deleteResult.get())

        let secondListResult = awaitResult({ self.client.listVaults(completion: $0)})
        guard let emptyList = try? secondListResult.get() else { XCTFail(); return }

        XCTAssertEqual(emptyList.count, 0)
    }

    func testChangeMasterPassword() {

    }

    func testAddItemToUnlockedVault() {
        self.useKeychain()
        self.setUsername("Foo")

        // put some known vault data in the store so it can be fetched.
        let tuple = self.populateServiceWithKnownVault()
        let secureVault = tuple.vault
        let secureVaultData = tuple.data
        self.unlockVault()

        // `Vault` is a wrapper of an id, we don't have to fetch for testing
        let vault = Vault(id: secureVault.id, owner: "", owners: [], createdAt: secureVault.createdAt, updatedAt: secureVault.updatedAt)

        let newLogin = VaultLogin(id: "Foo", createdAt: Date(), updatedAt: Date(), user: "Foo", url: "bar", name: "Birch", notes: VaultItemNote(value: "Go To Store"), password: VaultItemPassword(value: SecureFieldValue.plainText("SimplePassword"), created: Date(), replaced: Date()), previousPasswords: [])

        // Save the number of items currently in the vault
        let vaultItemCountBeforeAdd = secureVaultData.vaultData.login.count

        self.keyManager.encryptSecureFieldResult = Data(capacity: 10)

        // Add the item, make sure it doesn't throw an error
        XCTAssertNoThrow(try awaitResult( {self.client.add(item: newLogin, toVault: vault, completion: $0) }).get() )

        // Compare the value that gets written to the secure vault service.

        guard let paramBlobFormat = self.secureVaultClient.updateVaultParamBlobFormat,
              let paramBlob = self.secureVaultClient.updateVaultParamBlob else {
            return
        }

        XCTAssertEqual(paramBlobFormat, VaultSchema.latest.rawValue)

        // Decode the blob that was saved to the secure vault service so we can inspect it.
        guard let decodedBlob = try? VaultSchema.CurrentModelSchema.Decoder().decode(data: paramBlob) else { XCTFail(); return }

        XCTAssertEqual(decodedBlob.login.count, vaultItemCountBeforeAdd + 1)
        let newItemIsInVault = decodedBlob.login.contains { (item) -> Bool in
            return item.user == newLogin.user && item.url == newLogin.url
        }

        XCTAssertTrue(newItemIsInVault)
    }

    func testListVaultItems() {
        self.useKeychain()
        self.setUsername("Foo")

        let secureVault = self.populateServiceWithKnownVault().vault
        self.unlockVault()
        let vault = Vault(id: secureVault.id, owner: "", owners: [], createdAt: secureVault.createdAt, updatedAt: secureVault.updatedAt)

        let result = awaitResult { self.client.listVaultItems(inVault: vault, completion: $0)}

        guard let items = try? result.get() else { XCTFail(); return }

        XCTAssertEqual(items.count, 2)

        // compare indidivual properties.
    }

    func testUpdateLogin() {
        self.useKeychain()
        self.setUsername("Foo")

        // put some known vault data in the store so it can be fetched.
        let tuple = self.populateServiceWithKnownVault()
        let secureVault = tuple.vault
        self.unlockVault()

        // `Vault` is a wrapper of an id, we don't have to fetch for testing
        let vault = Vault(id: secureVault.id, owner: "", owners: [], createdAt: secureVault.createdAt, updatedAt: secureVault.updatedAt)

        // Get the vault items so we can change one
        guard let items = try? awaitResult({ self.client.listVaultItems(inVault: vault, completion: $0) }).get() else { XCTFail(); return }

        guard let update = items.first as? VaultLogin else { XCTFail(); return }

        // make some updates
        update.user = "Squirt"
        update.url = "keyboard.com"
        update.password = VaultItemPassword(value: "ThisCan'tGoOn")
        update.notes = VaultItemNote(value: "Hair Salon, Milk, Cookies, Vacation")

        // Save the `updated` property so we can make sure it changes
        let updatedAt = update.updatedAt

        // Save the updates to the password manager
        XCTAssertNoThrow(try awaitResult({ self.client.update(item: update, in: vault, completion: $0) }).get() )

        // Check that fetching the item again shows changes
        if let items = try? awaitResult({ self.client.listVaultItems(inVault: vault, completion: $0) }).get() {
            guard let itemThatShouldUpdate = items.first(where: {$0.id == update.id }) as? VaultLogin else { XCTFail(); return }
            XCTAssertEqual(itemThatShouldUpdate.user, update.user)
        }
        else {
            XCTFail(); return
        }

        // Compare the value that gets written to the secure vault service.
        guard let paramBlobFormat = self.secureVaultClient.updateVaultParamBlobFormat,
              let paramBlob = self.secureVaultClient.updateVaultParamBlob else { return }
        XCTAssertEqual(paramBlobFormat, VaultSchema.latest.rawValue)

        // Decode the blob that was saved to the secure vault service so we can inspect it.
        guard let decodedBlob = try? VaultSchema.CurrentModelSchema.Decoder().decode(data: paramBlob) else { XCTFail(); return }
        guard let updatedItem = decodedBlob.login.first(where: {$0.id == update.id}) else { XCTFail(); return }

        XCTAssertEqual(update.id, updatedItem.id)
        XCTAssertEqual(update.user, updatedItem.user)

        XCTAssertNotEqual(updatedAt, updatedItem.updatedAt)
    }

    func testRemoveVaultLoginUnlockedVault() {
        self.useKeychain()
        self.setUsername("Foo")

        // put some known vault data in the store so it can be fetched.
        let tuple = self.populateServiceWithKnownVault()
        let secureVault = tuple.vault
        let secureVaultData = tuple.data
        self.unlockVault()

        // `Vault` is a wrapper of an id, we don't have to fetch for testing
        let vault = Vault(id: secureVault.id, owner: "", owners: [], createdAt: secureVault.createdAt, updatedAt: secureVault.updatedAt)

        // Save the number of items currently in the vault
        let vaultItemCountBeforeAdd = secureVaultData.vaultData.login.count

        // Remove the item
        XCTAssertNoThrow(try awaitResult({ self.client.removeVaultItem(id: "1", from: vault, completion: $0)}).get())

        // Compare the value that gets written to the secure vault service.
        guard let paramBlobFormat = self.secureVaultClient.updateVaultParamBlobFormat,
              let paramBlob = self.secureVaultClient.updateVaultParamBlob else { return }

        XCTAssertEqual(paramBlobFormat, VaultSchema.latest.rawValue)

        // Decode the blob that was saved to the secure vault service so we can inspect it.
        guard let decodedBlob = try? VaultSchema.CurrentModelSchema.Decoder().decode(data: paramBlob) else { XCTFail(); return }

        // Check that the item count has decreased
        XCTAssertEqual(decodedBlob.login.count, vaultItemCountBeforeAdd - 1)
    }

    func testReset() {
        XCTAssertNoThrow(try self.client.reset())
        XCTAssertTrue(self.secureVaultClient.resetCalled)
        XCTAssertTrue(self.client.isLocked())
    }

    func testGetSecretCode() {
        let key = KeyDerivingKey(hexdecimalString: Array(0..<32).map { _ in return "F"}.joined())
        self.keyManager.getKeyDerivingKeyResult = key
        self.service.userSubject = nil
        XCTAssertEqual(self.client.getSecretCode(), "00000-FFFFFF-FFFFF-FFFFF-FFFFF-FFFFF-FFFFFF")

        self.service.userSubject = "F7FF78AB4C3F4423921989AF6905538B"
        XCTAssertEqual(self.client.getSecretCode(), "DF286-FFFFFF-FFFFF-FFFFF-FFFFF-FFFFF-FFFFFF")
    }
    
    func testGetEntitlementState() {
        self.unlockVault()
        
        let testVault = VaultMetadata(id: "entitled to your face", owner: "", version: 1, blobFormat: "JSON", createdAt: Date(), updatedAt: Date(), owners: [Owner(id: "foo", issuer: "sudoplatform.sudoservice")])
        self.secureVaultClient.listVaultsMetadataOnlyResult = .success([testVault])

        let testSudo = Sudo(id: "foo", version: 1, createdAt: Date(), updatedAt: Date())
        self.sudoProfilesclient.listSudosResult = ListSudosResult.success(sudos: [testSudo])

        self.entitlements.getEntitlementsReturn = EntitlementsSet(name: "",
                                                                  description: "",
                                                                  entitlements: [Entitlement(name: "sudoplatform.vault.vaultMaxPerSudo", description: nil, value: 1)],
                                                                  version: 0,
                                                                  created: Date(),
                                                                  updated: Date())

        if let state = try? awaitResult( { self.client.getEntitlementState(completion: $0) }).get() {
            guard let item = state.first else { XCTFail(); return }
            XCTAssertEqual(item.name, .maxVaultPerSudo)
            XCTAssertEqual(item.limit, 1)
            XCTAssertEqual(item.value, 1)
        } else {
            XCTFail(); return
        }
    }

    private func populateServiceWithKnownVault() -> (vault: SudoSecureVault.Vault, data: VaultProxy) {
        let data = self.createVaultForTesting()
        let encoded = try! VaultSchema.CurrentModelSchema.Encoder().encode(vault: data.vaultData)
        let secureVault = Vault.init(id: "1", owner: "", version: 1, blobFormat: data.blobFormat.rawValue, createdAt: data.createdAt, updatedAt: data.updatedAt, owners: [], blob: encoded)
        self.secureVaultClient.listVaultsResult = .success([secureVault])
        return (vault: secureVault, data: data)
    }

    private func isError(_ error: Error, ofType type: PasswordManagerError.ErrorType) -> Bool {
        guard let clientError = (error as? PasswordManagerError) else { return false }
        return clientError.type == type
    }

    func createVaultForTesting() -> VaultProxy {
        let now = Date()
        var first = VaultProxy(secureVaultId: "1",
                               blobFormat: VaultSchema.latest,
                               createdAt: now,
                               updatedAt: now,
                               version: 1,
                               owner: "",
                               owners: [],
                               vaultData: VaultSchema.CurrentModelSchema.Vault(bankAccount: [], creditCard: [], generatedPassword: [], login: [], schemaVersion: 1))

        first.vaultData.login.append(vaultItem1)
        first.vaultData.login.append(vaultItem2)
        return first
    }

    lazy var vaultItem1: VaultLoginProxy = {

        return VaultLoginProxy(createdAt: Date(),
                               id: "1",
                               name: "Item1",
                               notes: .init(secureValue: "Hello World"),
                               updatedAt: Date(),
                               type: .login,
                               password: .init(secureValue: "SecretPassword", createdAt: Date(), replacedAt: Date()),
                               url: "npr.org",
                               user: "Joe")
    }()

    lazy var vaultItem2: VaultLoginProxy = {
        return VaultLoginProxy(createdAt: Date(),
                               id: "2",
                               name: "Item2",
                               notes: .init(secureValue: "Hello World"),
                               updatedAt: Date(),
                               type: .login,
                               password: .init(secureValue: "SecretPassword", createdAt: Date(), replacedAt: Date()),
                               url: "cnn.com",
                               user: "Steve")
    }()
}

/// When we need an error - because `NSError()` doesn't work.
extension NSError {
    static var some: NSError {
        return NSError(domain: UUID().uuidString, code: 0, userInfo: nil)
    }
}

// We need raw seemingly random data sometimes to test against
extension KeyDerivingKey {
    static var withUUID: Data {
        return UUID().uuidString.data(using: .utf8)!
    }
}


