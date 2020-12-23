//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
@testable import SudoPasswordManager
import SudoSecureVault
import SudoEntitlements
import SudoProfiles

class PasswordClientServiceMock: PasswordClientService {

    var secureVaultClient: SudoSecureVaultClient
    var sudoUserClient: SudoUserClient
    var keyManager: PasswordManagerKeyManager
    var entitlementsClient: SudoEntitlementsClient
    var sudoProfilesClient: SudoProfilesClient

    var userSubject: String?
    func getUserSubject() -> String? {
        return self.userSubject
    }

    init(client: SudoSecureVaultClient, sudoUserClient: SudoUserClient, keyManager: PasswordManagerKeyManager, entitlementsClient: SudoEntitlementsClient, sudoProfilesClient: SudoProfilesClient) {
        self.secureVaultClient = client
        self.sudoUserClient = sudoUserClient
        self.keyManager = keyManager
        self.entitlementsClient = entitlementsClient
        self.sudoProfilesClient = sudoProfilesClient
    }

    var getOwnershipProofCalled = false
    var getOwnershipProofParamSudoId: String?
    var getOwnershipProofResult: Result<String, Error> = .success("")
    func getOwnershipProof(sudoId: String, completion: @escaping (Result<String, Error>) -> Void) {
        getOwnershipProofCalled = true
        getOwnershipProofParamSudoId = sudoId
        completion(getOwnershipProofResult)
    }
}

//class CrytpoProviderMock: CryptographyProvider {
//
//    var generateKdkResult: Result<KeyDerivingKey, Error>!
//    func generateKeyDerivingKey() throws -> KeyDerivingKey {
//        return try generateKdkResult.get()
//    }
//
//    // 128 bit key = 16 bytes
//    var generateSecureFieldKeyResult: Result<Data, Error> = .success(Data(capacity: 128<<3))
//    func generateSecureFieldKey() throws -> Data {
//        return try generateSecureFieldKeyResult.get()
//    }
//
//    var encryptSecureFieldSpy: (data: Data, key: Data)?
//    var encryptSecureFieldResult: Result<Data, Error> = .failure(NSError.some)
//    func encryptSecureField(data: Data, usingKey key: Data) throws -> Data {
//        encryptSecureFieldSpy = (data, key)
//        return try encryptSecureFieldResult.get()
//    }
//
//    var decryptSecureFieldSpy: (data: Data, key: Data)?
//    var decryptSecureFieldResult: Result<Data, Error> = .failure(NSError.some)
//    func decryptSecureField(data: Data, usingKey key: Data) throws -> Data {
//        decryptSecureFieldSpy = (data, key)
//        return try encryptSecureFieldResult.get()
//    }
//}
//
//class KeyDerivingKeyStoreMock: KeyDerivingKeyStore {
//    var key: KeyDerivingKey?
//    var getkeyError: Error?
//    func getKey(name: String) throws -> KeyDerivingKey? {
//        if let error = getkeyError { throw error }
//        return key
//    }
//
//    var addKeyError: Error?
//    func add(key: KeyDerivingKey, name: String) throws {
//        if let error = addKeyError { throw error }
//        self.key = key
//    }
//
//    var resetKeysSpy: Bool = false
//    func resetKeys() {
//        self.resetKeysSpy = true
//    }
//}
