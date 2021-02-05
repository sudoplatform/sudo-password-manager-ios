//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

class VaultFactory {

    let crypto: PasswordManagerKeyManager
    weak var passwordManagerClient: SudoPasswordManagerClient?

    init(client: SudoPasswordManagerClient, keyManager: PasswordManagerKeyManager) {
        self.passwordManagerClient = client
        self.crypto = keyManager
    }

    // MARK: - Public to internal

    /// Converts between the user facing `VaultLogin` to the internal vault format `VaultLoginProxy`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - login: The `VaultLogin` to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a `VaultLoginProxy`.
    func createVaultLoginProxy(from login: VaultLogin, vaultKey: Data) throws -> VaultLoginProxy {
        let notes = try login.notes.map { note in
            return try self.createVaultSecureFieldProxy(from: note, vaultKey: vaultKey)
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

    /// Converts between the user facing `VaultCreditCard` to the internal vault format `VaultCreditCardProxy`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - creditCard: The `VaultCreditCard` to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a `VaultCreditCardProxy`.
    func createVaultCreditCardProxy(from creditCard: VaultCreditCard, vaultKey: Data) throws -> VaultCreditCardProxy {
        let notes = try creditCard.notes.map { note in
            return try self.createVaultSecureFieldProxy(from: note, vaultKey: vaultKey)
        }

        let cardNumber = try creditCard.cardNumber.map { cardNumber in
            return try self.createVaultSecureFieldProxy(from: cardNumber, vaultKey: vaultKey)
        }

        let cardSecurityCode = try creditCard.cardSecurityCode.map { cardSecurityCode in
            return try self.createVaultSecureFieldProxy(from: cardSecurityCode, vaultKey: vaultKey)
        }

        return VaultCreditCardProxy(createdAt: creditCard.createdAt,
                                    id: creditCard.id,
                                    name: creditCard.name,
                                    notes: notes,
                                    updatedAt: creditCard.updatedAt,
                                    type: .creditCard,
                                    cardExpiration: creditCard.cardExpiration,
                                    cardName: creditCard.cardName,
                                    cardNumber: cardNumber,
                                    cardSecurityCode: cardSecurityCode,
                                    cardType: creditCard.cardType)
    }

    /// Converts between the user facing `VaultBankAccount` to the internal vault format `VaultBankAccountProxy`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - bankAccount: The `VaultBankAccount` to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a `VaultBankAccountProxy`.
    func createVaultBankAccountProxy(from bankAccount: VaultBankAccount, vaultKey: Data) throws -> VaultBankAccountProxy {
        let notes = try bankAccount.notes.map { note in
            return try self.createVaultSecureFieldProxy(from: note, vaultKey: vaultKey)
        }

        let accountNumber = try bankAccount.accountNumber.map { accountNumber in
            return try self.createVaultSecureFieldProxy(from: accountNumber, vaultKey: vaultKey)
        }

        let accountPin = try bankAccount.accountPin.map { accountPin in
            return try self.createVaultSecureFieldProxy(from: accountPin, vaultKey: vaultKey)
        }

        return VaultBankAccountProxy(createdAt: bankAccount.createdAt,
                                    id: bankAccount.id,
                                    name: bankAccount.name,
                                    notes: notes,
                                    updatedAt: bankAccount.updatedAt,
                                    type: .bankAccount,
                                    accountNumber: accountNumber,
                                    accountPin: accountPin,
                                    accountType: bankAccount.accountType,
                                    bankName: bankAccount.bankName,
                                    branchAddress: bankAccount.branchAddress,
                                    branchPhone: bankAccount.branchPhone,
                                    ibanNumber: bankAccount.ibanNumber,
                                    routingNumber: bankAccount.routingNumber,
                                    swiftCode: bankAccount.swiftCode)
    }

    /// Converts between the user facing `VaultItemValue` to the internal vault format `VaultSecureField`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - value: The item value  to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a `VaultSecureFieldProxy`.
    private func createVaultSecureFieldProxy(from value: VaultItemValue, vaultKey: Data) throws -> VaultSecureFieldProxy {
        let secureField = try self.createVaultSecureField(from: value.value, vaultKey: vaultKey)
        return VaultSecureFieldProxy(secureValue: secureField.secureValue)
    }

    /// Converts between the user facing `VaultItemPassword` to the internal vault format `VaultPasswordProxy`.
    /// If a secure field was already encrypted it is left in that state and not decrypted and reencrypted.
    /// - Parameters:
    ///   - password: The note to be converted
    ///   - vaultKey: The vault key used to encrypt the item.
    /// - Throws: A vault encryption error, or a data conversion error if the input can't be converted.
    /// - Returns: The on-disk format of a `VaultPasswordProxy`.
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
        let notes = login.notes.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }
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

    func createVaultCreditCard(from creditCard: VaultCreditCardProxy, revealKey: Data) -> VaultCreditCard {
        let notes = creditCard.notes.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }
        let cardNumber = creditCard.cardNumber.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }
        let cardSecurityCode = creditCard.cardSecurityCode.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }

        return VaultCreditCard(id: creditCard.id,
                          createdAt: creditCard.createdAt,
                          updatedAt: creditCard.updatedAt,
                          name: creditCard.name,
                          notes: notes,
                          cardType: creditCard.cardType,
                          cardName: creditCard.cardName,
                          cardExpiration: creditCard.cardExpiration,
                          cardNumber: cardNumber,
                          cardSecurityCode: cardSecurityCode)
    }

    func createVaultBankAccount(from bankAccount: VaultBankAccountProxy, revealKey: Data) -> VaultBankAccount {
        let notes = bankAccount.notes.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }
        let accountNumber = bankAccount.accountNumber.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }
        let accountPin = bankAccount.accountPin.map { self.createVaultItemValue(from: $0, revealKey: revealKey) }

        return VaultBankAccount(id: bankAccount.id,
                                createdAt: bankAccount.createdAt,
                                updatedAt: bankAccount.updatedAt,
                                name: bankAccount.name,
                                notes: notes,
                                accountType: bankAccount.accountType,
                                bankName: bankAccount.bankName,
                                branchAddress: bankAccount.branchAddress,
                                branchPhone: bankAccount.branchPhone,
                                ibanNumber: bankAccount.ibanNumber,
                                routingNumber: bankAccount.routingNumber,
                                swiftCode: bankAccount.swiftCode,
                                accountNumber: accountNumber,
                                accountPin: accountPin)
    }

    private func createVaultItemValue(from value: VaultNoteProxy, revealKey: Data) -> VaultItemValue {
        return VaultItemValue(value: self.createSecureFieldValue(ciperText: value.secureValue, revealKey: revealKey))
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
