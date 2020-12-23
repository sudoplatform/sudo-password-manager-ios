//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager
import SudoUser
import CommonCrypto

protocol PasswordManagerKeyManager {

    /// Gets the curren users key derriving key from the key store
    func getKeyDerivingKey() throws -> KeyDerivingKey?

    /// Sets the current users key derriving key in the key store
    func set(keyDerivingKey: KeyDerivingKey) throws

    /// Retrieves a symmetric key from the current user's secure store.
    ///
    /// - Parameter name: Name of the symmetric key to be retrieved.
    /// - Throws: `SudoKeyManagerError`.
    func getSymmetricKey(_ name: String) throws -> Data?

    /// Generates and securely stores a symmetric key in the current users secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to be generated.
    ///   - isExportable: indicates whether or not the password is exportable.
    /// - Throws: `SudoKeyManagerError`.
    func generateSymmetricKey(_ name: String, isExportable: Bool) throws

    /// Encrypts the given data with the specified symmetric key stored in the current users secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    /// - Throws: `SudoKeyManagerError`.
    func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data

    /// Decrypts the given data with the specified symmetric key stored in the current users secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    /// - Throws: `SudoKeyManagerError`.
    func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data

    func generateKeyDerivingKey() throws -> KeyDerivingKey

    func encryptSecureField(data: Data, usingKey key: Data) throws -> Data

    func decryptSecureField(data: Data, usingKey key: Data) throws -> Data

    /// Removes all users keys associated with this key manager
    func removeAllKeys() throws
}

class DefaultPasswordManagerKeyManager: PasswordManagerKeyManager {

    let userClient: SudoUserClient

    private let kdkName: String = "keyDerivingKey"

    init(userClient: SudoUserClient) {
        self.userClient = userClient
    }

    private func getSudoKeyManager() throws -> SudoKeyManager {
        return SudoKeyManagerImpl(serviceName: "com.sudoplatform.passwordmanager", keyTag: "com.sudoplatform", namespace: "")
    }

    func getKeyDerivingKey() throws -> KeyDerivingKey? {
        guard let user = try? userClient.getUserName() else {
            throw PasswordManagerError.notAuthorized
        }

        let keyName = "\(user).\(kdkName)"
        return try self.getSymmetricKey(keyName)
    }

    func set(keyDerivingKey: KeyDerivingKey) throws {
        guard let user = try? userClient.getUserName() else {
            throw PasswordManagerError.notAuthorized
        }
        let keyName = "\(user).\(kdkName)"
        try self.getSudoKeyManager().addSymmetricKey(keyDerivingKey, name: keyName)
    }

    func getSymmetricKey(_ name: String) throws -> Data? {
        return try self.getSudoKeyManager().getSymmetricKey(name)
    }

    func generateSymmetricKey(_ name: String, isExportable: Bool) throws {
        return try self.getSudoKeyManager().generateSymmetricKey(name, isExportable: isExportable)
    }

    func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        return try self.getSudoKeyManager().encryptWithSymmetricKey(name, data: data)
    }

    func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        return try self.getSudoKeyManager().decryptWithSymmetricKey(name, data: data)
    }

    func generateKeyDerivingKey() throws -> KeyDerivingKey {
        let keySize = 128
        // createRandomBytes expects key length in bytes so divide bit count by 8
        return try self.getSudoKeyManager().createRandomData(keySize >> 3)
    }

    func encryptSecureField(data: Data, usingKey key: Data) throws -> Data {
        let km = try self.getSudoKeyManager()
        let iv = try km.createRandomData(kCCBlockSizeAES128)
        let encryptedData = try km.encryptWithSymmetricKey(key, data: data, iv: iv)
        return iv + encryptedData
    }

    func decryptSecureField(data: Data, usingKey key: Data) throws -> Data {
        let ivLength = kCCBlockSizeAES128
        guard data.count >= ivLength else {
            throw PasswordManagerError.invalidFormat
        }
        let iv = data.prefix(upTo: ivLength)
        let ciperText = data.suffix(from: ivLength)
        return try self.getSudoKeyManager().decryptWithSymmetricKey(key, data: ciperText, iv: iv)
    }

    func removeAllKeys() throws {
        try self.getSudoKeyManager().removeAllKeys()
    }
}
