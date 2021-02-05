//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoSecureVault
import SudoLogging

/// The "internal" vaults. These objects have been decoded from the secure vault blob format and
/// are the canonical internal vault format.
///
/// These are bridged (either directly or through an adapter or controller) to the external types
/// returned to users of the SDK.
///
/// Some of these are their own types, but others are type alias to the interal vault json.
internal typealias VaultLoginProxy = VaultSchema.CurrentModelSchema.Login
internal typealias VaultCreditCardProxy = VaultSchema.CurrentModelSchema.CreditCard
internal typealias VaultBankAccountProxy = VaultSchema.CurrentModelSchema.BankAccount
internal typealias VaultNoteProxy = VaultSchema.CurrentModelSchema.SecureField
internal typealias VaultPasswordProxy = VaultSchema.CurrentModelSchema.PasswordField
internal typealias VaultSecureFieldProxy = VaultSchema.CurrentModelSchema.SecureField


struct VaultProxy {

    struct VaultOwner {
        var id: String
        var issuer: String
    }

    /// Unique ID of the vault storage record on the service
    let secureVaultId: String

    /// Blob format specifier.
    let blobFormat: VaultSchema

    /// Date/time at which the vault was created.
    let createdAt: Date

    /// Date/time at which the vault was last modified.
    var updatedAt: Date

    /// Version from the SecureVault metadata
    var version: Int

    var owner: String

    var owners: [VaultOwner]

    /// The `vault`.
    var vaultData: VaultSchema.CurrentModelSchema.Vault

    /// Creates a new vault.
    /// - Parameter secureFieldKey: The base64 encoded key to be used when encoding secure fields.
    init(ownershipProof: String) {
        self.secureVaultId = ""
        self.blobFormat = VaultSchema.latest
        self.createdAt = Date()
        self.updatedAt = createdAt
        self.version = 0
        self.owner = ownershipProof
        self.owners = []
        self.vaultData = VaultSchema.CurrentModelSchema.Vault(bankAccount: [], creditCard: [], generatedPassword: [], login: [], schemaVersion: 0)
    }

    init(secureVaultId: String,
         blobFormat: VaultSchema,
         createdAt: Date,
         updatedAt: Date,
         version: Int,
         owner: String,
         owners: [VaultOwner],
         vaultData: VaultSchema.CurrentModelSchema.Vault) {
        self.secureVaultId = secureVaultId
        self.blobFormat = blobFormat
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.owner = owner
        self.owners = owners
        self.vaultData = vaultData
    }

    init?(metadata: Metadata, vaultData: VaultSchema.CurrentModelSchema.Vault) {
        self.secureVaultId = metadata.id
        guard let format = VaultSchema(rawValue: metadata.blobFormat) else {
            return nil
        }
        self.blobFormat = format
        self.createdAt = metadata.createdAt
        self.updatedAt = metadata.updatedAt
        self.version = metadata.version
        self.owner = metadata.owner
        self.owners = metadata.owners.map({return VaultProxy.VaultOwner.init(id: $0.id, issuer: $0.issuer)})
        self.vaultData = vaultData
    }
}

/// Local storage of vaults.
class VaultStore {

    /// A collection of secure vaults that have been decoded
    private var vaults: [String: VaultProxy] = [:]

    /// Imports an array of secure vaults fetched from from the secure vault service
    /// Intended to be used during unlock when all the vaults are downloaded.
    func importSecureVaults(_ vaults: [SudoSecureVault.Vault]) {

        for vault in vaults {
            guard let schema = VaultSchema(rawValue: vault.blobFormat) else {
                Logger.shared.debug("Failed to import vault. Unknown schema format: \(vault.blobFormat)")
                break
            }

            do {
                let parsed = try schema.decodeSecureVault(vault: vault)
                self.vaults[vault.id] = parsed
            } catch {
                Logger.shared.debug("Failed to decode vault: \(error)")
            }
        }
    }

    /// Imports a `VaultProxy` into the store. Intended to be used when a new vault is created
    func importVault(_ vault: VaultProxy) {
        self.vaults[vault.secureVaultId] = vault
    }

    func updateVault(with metadata: SudoSecureVault.VaultMetadata) {
        guard let proxy = self.getVault(withId: metadata.id) else { return }
        guard let update = VaultProxy(metadata: metadata, vaultData: proxy.vaultData) else { return }
        self.vaults[metadata.id] = update
    }

    /// Remove all vaults from the store.
    func removeAll() {
        self.vaults.removeAll()
    }

    // MARK: Vault store access

    /// Lists all vaults in the store
    func listVaults() -> [VaultProxy] {
        return self.vaults.values.compactMap({$0})
    }

    /// Fetches the vault with the specified id.
    func getVault(withId id: String) -> VaultProxy? {
        return self.vaults[id]
    }

    func deleteVault(withId id: String) {
        self.vaults[id] = nil
    }

    // MARK: Vault Item

    func add(login: VaultLoginProxy, toVaultWithId id: String) throws {
        guard var vault = self.vaults[id] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.login.append(login)
        self.vaults[id] = vault
    }

    func add(creditCard: VaultCreditCardProxy, toVaultWithId id: String) throws {
        guard var vault = self.vaults[id] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.creditCard.append(creditCard)
        self.vaults[id] = vault
    }

    func add(bankAccount: VaultBankAccountProxy, toVaultWithId id: String) throws {
        guard var vault = self.vaults[id] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.bankAccount.append(bankAccount)
        self.vaults[id] = vault
    }

    func update(login: VaultLoginProxy, in vaultId: String) throws {
        guard var vault = self.vaults[vaultId] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.login.removeAll(where: { $0.id == login.id })
        var mutableLogin = login
        mutableLogin.updatedAt = Date()
        vault.vaultData.login.append(mutableLogin)
        self.vaults[vaultId] = vault
    }

    func update(creditCard: VaultCreditCardProxy, in vaultId: String) throws {
        guard var vault = self.vaults[vaultId] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.creditCard.removeAll(where: { $0.id == creditCard.id })
        var mutableCreditCard = creditCard
        mutableCreditCard.updatedAt = Date()
        vault.vaultData.creditCard.append(mutableCreditCard)
        self.vaults[vaultId] = vault
    }

    func update(bankAccount: VaultBankAccountProxy, in vaultId: String) throws {
        guard var vault = self.vaults[vaultId] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.bankAccount.removeAll(where: { $0.id == bankAccount.id })
        var mutableBankAccount = bankAccount
        mutableBankAccount.updatedAt = Date()
        vault.vaultData.bankAccount.append(mutableBankAccount)
        self.vaults[vaultId] = vault
    }

    func removeVaultItem(withId id: String, vaultId: String) throws {
        guard var vault = self.vaults[vaultId] else { throw PasswordManagerError.invalidVault }
        vault.vaultData.login.removeAll(where: { $0.id == id })
        vault.vaultData.creditCard.removeAll(where: { $0.id == id })
        vault.vaultData.bankAccount.removeAll(where: { $0.id == id })
        self.vaults[vaultId] = vault
    }
}

enum VaultEncodingError: Error {
    /// The vault schema doesn't match known versions.
    case invalidSchema
}
