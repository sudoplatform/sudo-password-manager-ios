//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

class VaultFactory {

    let crypto: PasswordManagerKeyManager
    weak var passwordManagerClient: PasswordManagerClient?

    init(client: PasswordManagerClient, keyManager: PasswordManagerKeyManager) {
        self.passwordManagerClient = client
        self.crypto = keyManager
    }

    // MARK: - Public to internal

    /// Converts between the user facing `VaultLogin` to the internal vault format `VaultLoginProxy`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - login: The VaultLogin to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a VaultLoginProxy.
    func createVaultLoginProxy(from login: VaultLogin, vaultKey: Data) throws -> VaultLoginProxy {
        let notes = try login.notes.map { note in
            return try self.createVaultNoteProxy(from: note, vaultKey: vaultKey)
        }

        let password = try login.password.map { (password) in
            return try self.createVaultPasswordProxy(from: password, vaultKey: vaultKey)
        }

        return VaultLoginProxy(createdAt: login.createdAt,
                               id: login.id,
                               name: login.name,
                               notes: notes,
                               updatedAt: login.updatedAt,
                               type: .login,
                               password: password,
                               url: login.url,
                               user: login.user)
    }

    /// Converts between the user facing `Note` to the internal vault format `Note`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - note: The note to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a note.
    private func createVaultNoteProxy(from note: VaultItemNote, vaultKey: Data) throws -> VaultNoteProxy {
        let secureField = try self.createVaultSecureField(from: note.value, vaultKey: vaultKey)
        return VaultNoteProxy(secureValue: secureField.secureValue)
    }

    /// Converts between the user facing `VaultItemPassword` to the internal vault format `VaultPasswordProxy`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - password: The note to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a Password.
    private func createVaultPasswordProxy(from password: VaultItemPassword, vaultKey: Data) throws -> VaultPasswordProxy {
        let secureField = try self.createVaultSecureField(from: password.value, vaultKey: vaultKey)
        return VaultPasswordProxy(secureValue: secureField.secureValue, createdAt: password.created, replacedAt: password.replaced)
    }

    /// Converts a secure field from a user facing `SecureFieldValue` to the encrypted version to be stored
    /// in the vault. If the field is already encrypted, no conversion is made.
    /// - Parameters:
    ///   - value: the value that may need encrypting
    ///   - vaultKey: vault key to use to encrypt
    /// - Throws: A vault encryption error, or PasswordManagerClientError.invalidFormat if the input can't be converted.
    /// - Returns: the vault secure proxy.
    private func createVaultSecureField(from value: SecureFieldValue, vaultKey: Data) throws -> VaultSecureFieldProxy {
        switch value {
        case .cipherText(let ciperText, _):
            return VaultSecureFieldProxy(secureValue: ciperText)
        case .plainText(let plainText):
            guard let data = plainText.data(using: .utf8) else {
                Logger.shared.info("Failed to convert string using utf8 encoding")
                throw PasswordManagerError.invalidFormat
            }
            let cipherText = try self.crypto.encryptSecureField(data: data, usingKey: vaultKey).base64EncodedString()
            return VaultSecureFieldProxy(secureValue: cipherText)
        }
    }

    // MARK: - Internal to public

    func createVaultLogin(from login: VaultLoginProxy, revealKey: Data) -> VaultLogin {
        let notes = login.notes.map { self.createVaultItemNote(from: $0, revealKey: revealKey) }
        let password = login.password.map { self.createVaultItemPassword(from: $0, revealKey: revealKey)}

        return VaultLogin(id: login.id,
                          createdAt: login.createdAt,
                          updatedAt: login.updatedAt,
                          user: login.user,
                          url: login.url,
                          name: login.name,
                          notes: notes,
                          password: password,
                          previousPasswords: [])
    }

    private func createVaultItemNote(from note: VaultNoteProxy, revealKey: Data) -> VaultItemNote {
        return VaultItemNote(value: self.createSecureFieldValue(ciperText: note.secureValue, revealKey: revealKey))
    }

    private func createVaultItemPassword(from password: VaultPasswordProxy, revealKey: Data) -> VaultItemPassword {
        return VaultItemPassword(value: self.createSecureFieldValue(ciperText: password.secureValue, revealKey: revealKey),
                                 created: password.createdAt,
                                 replaced: password.replacedAt)
    }

    private func createSecureFieldValue(ciperText: String, revealKey: Data) -> SecureFieldValue {
        let revealFunction = { [weak self] () -> String in
            guard let self = self, let client = self.passwordManagerClient, client.isLocked() == false else {
                throw PasswordManagerError.vaultLocked
            }

            guard let ciperData = Data(base64Encoded: ciperText) else {
                throw PasswordManagerError.invalidFormat
            }

            let plainTextData = try self.crypto.decryptSecureField(data: ciperData, usingKey: revealKey)

            guard let plainText = String(data: plainTextData, encoding: .utf8) else {
                throw PasswordManagerError.invalidFormat
            }

            return plainText
        }

        return SecureFieldValue.cipherText(ciperText, revealFunction)
    }
}
