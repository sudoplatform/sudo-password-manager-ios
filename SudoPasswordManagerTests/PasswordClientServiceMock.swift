//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
@testable import SudoPasswordManager

class PasswordClientServiceMock: PasswordClientService {
    var cryptoProvider: CryptographyProvider
    var keyStore: KeyDerivingKeyStore
    var secureVaultClient: SudoSecureVaultClient
    var sudoUserClient: SudoUserClient

    var userSubject: String?
    func getUserSubject() -> String? {
        return self.userSubject
    }

    init(client: SudoSecureVaultClient, cryptoProvider: CryptographyProvider, keyStore: KeyDerivingKeyStore, sudoUserClient: SudoUserClient) {
        self.secureVaultClient = client
        self.cryptoProvider = cryptoProvider
        self.keyStore = keyStore
        self.sudoUserClient = sudoUserClient
    }

    var key: KeyDerivingKey?
    var getkeyError: Error?
    func getKey() throws -> KeyDerivingKey? {
        if let error = getkeyError { throw error }
        return key
    }

    var setKeyError: Error?
    var setKeySpy: KeyDerivingKey?
    func set(key: KeyDerivingKey) throws {
        self.setKeySpy = key
        if let error = setKeyError { throw error }
        self.key = key
    }
}

class CrytpoProviderMock: CryptographyProvider {

    var generateKdkResult: Result<KeyDerivingKey, Error>!
    func generateKeyDerivingKey() throws -> KeyDerivingKey {
        return try generateKdkResult.get()
    }

    // 128 bit key = 16 bytes
    var generateSecureFieldKeyResult: Result<Data, Error> = .success(Data(capacity: 128<<3))
    func generateSecureFieldKey() throws -> Data {
        return try generateSecureFieldKeyResult.get()
    }

    var encryptSecureFieldSpy: (data: Data, key: Data)?
    var encryptSecureFieldResult: Result<Data, Error> = .failure(NSError.some)
    func encryptSecureField(data: Data, usingKey key: Data) throws -> Data {
        encryptSecureFieldSpy = (data, key)
        return try encryptSecureFieldResult.get()
    }

    var decryptSecureFieldSpy: (data: Data, key: Data)?
    var decryptSecureFieldResult: Result<Data, Error> = .failure(NSError.some)
    func decryptSecureField(data: Data, usingKey key: Data) throws -> Data {
        decryptSecureFieldSpy = (data, key)
        return try encryptSecureFieldResult.get()
    }
}

class KeyDerivingKeyStoreMock: KeyDerivingKeyStore {
    var key: KeyDerivingKey?
    var getkeyError: Error?
    func getKey(name: String) throws -> KeyDerivingKey? {
        if let error = getkeyError { throw error }
        return key
    }

    var addKeyError: Error?
    func add(key: KeyDerivingKey, name: String) throws {
        if let error = addKeyError { throw error }
        self.key = key
    }

    var resetKeysSpy: Bool = false
    func resetKeys() {
        self.resetKeysSpy = true
    }
}
