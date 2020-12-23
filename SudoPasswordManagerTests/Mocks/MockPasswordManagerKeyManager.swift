//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import SudoPasswordManager

class MockPasswordManagerKeyManager: PasswordManagerKeyManager  {

    var resetCalled = false
    var resetError: Error?
    func reset() throws {
        resetCalled = true
        if let error = resetError { throw error }
    }

    var getKeyDerivingKeyCalled = false
    var getKeyDerivingKeyError: Error?
    var getKeyDerivingKeyResult: KeyDerivingKey?
    func getKeyDerivingKey() throws -> KeyDerivingKey? {
        getKeyDerivingKeyCalled = true
        if let error = getKeyDerivingKeyError { throw error }
        return getKeyDerivingKeyResult
    }

    var setKeyDerivingKeyCalled = false
    var setKeyDerivingKeyParamKey: KeyDerivingKey?
    var setKeyDerivingKeyError: Error?
    func set(keyDerivingKey: KeyDerivingKey) throws {
        setKeyDerivingKeyParamKey = keyDerivingKey
        setKeyDerivingKeyCalled = true
        if let error = setKeyDerivingKeyError { throw error }
    }

    var getSymmetricKeyCalled = false
    var getSymmetricKeyParamName: String?
    var getSymmetricKeyError: Error?
    var getSymmetricKeyResult: Data?
    func getSymmetricKey(_ name: String) throws -> Data? {
        getSymmetricKeyParamName = name
        getSymmetricKeyCalled = true
        if let error = getSymmetricKeyError { throw error }
        return getSymmetricKeyResult
    }

    var generateSymmetricKeyCalled = false
    var generateSymmetricKeyParamName: String?
    var generateSymmetricKeyParamIsExportable: Bool?
    var generateSymmetricKeyError: Error?
    func generateSymmetricKey(_ name: String, isExportable: Bool) throws {
        self.generateSymmetricKeyParamName = name
        self.generateSymmetricKeyParamIsExportable = isExportable
        generateSymmetricKeyCalled = true
        if let error = generateSymmetricKeyError { throw error }
    }

    var encryptWithSymmetricKeyCalled = false
    var encryptWithSymmetricKeyParamName: String?
    var encryptWithSymmetricKeyParamData: Data?
    var encryptWithSymmetricKeyError: Error?
    var encryptWithSymmetricKeyResult: Data = Data()
    func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        encryptWithSymmetricKeyCalled = true
        encryptWithSymmetricKeyParamName = name
        encryptWithSymmetricKeyParamData = data
        if let error = encryptWithSymmetricKeyError { throw error }
        return encryptWithSymmetricKeyResult
    }

    var decryptWithSymmetricKeyCalled = false
    var decryptWithSymmetricKeyParamName: String?
    var decryptWithSymmetricKeyParamData: Data?
    var decryptWithSymmetricKeyError: Error?
    var decryptWithSymmetricKeyResult: Data = Data()
    func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        decryptWithSymmetricKeyCalled = true
        decryptWithSymmetricKeyParamName = name
        decryptWithSymmetricKeyParamData = data
        if let error = decryptWithSymmetricKeyError { throw error }
        return decryptWithSymmetricKeyResult
    }

    var generateKeyDerivingKeyCalled = false
    var generateKeyDerivingKeyError: Error?
    var generateKeyDerivingKeyResult: KeyDerivingKey = KeyDerivingKey()
    func generateKeyDerivingKey() throws -> KeyDerivingKey {
        generateKeyDerivingKeyCalled = true
        if let error = generateKeyDerivingKeyError { throw error }
        return generateKeyDerivingKeyResult
    }

    var encryptSecureFieldCalled = false
    var encryptSecureFieldParamData: Data?
    var encryptSecureFieldParamKey: Data?
    var encryptSecureFieldError: Error?
    var encryptSecureFieldResult: Data?
    func encryptSecureField(data: Data, usingKey key: Data) throws -> Data {
        encryptSecureFieldCalled = true
        encryptSecureFieldParamData = data
        encryptSecureFieldParamKey = key
        if let error = encryptSecureFieldError { throw error }
        return encryptSecureFieldResult ?? data
    }

    var decryptSecureFieldCalled = false
    var decryptSecureFieldParamData: Data?
    var decryptSecureFieldParamKey: Data?
    var decryptSecureFieldError: Error?
    var decryptSecureFieldResult: Data?
    func decryptSecureField(data: Data, usingKey key: Data) throws -> Data {
        decryptSecureFieldCalled = true
        decryptSecureFieldParamData = data
        decryptSecureFieldParamKey = key
        if let error = decryptSecureFieldError { throw error }
        return decryptSecureFieldResult ?? data
    }

    var removeAllKeysCalled = false
    var removeAllKeysError: Error?
    func removeAllKeys() throws {
        removeAllKeysCalled = true
        if let error = removeAllKeysError { throw error }
    }
}
