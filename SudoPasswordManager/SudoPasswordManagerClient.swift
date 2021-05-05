//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PDFKit

/// Registration status of the password manager
public enum PasswordManagerRegistrationStatus {
    /// Returning user, known device.  User can interact with vaults after unlocking with master password.
    case registered

    /// New User, new device. This is a first time user.  User must choose a master password and register.
    case notRegistered

    /// Returning user, new device. Password manager requires the secret code which was generated when they first registered.
    case missingSecretCode
}

/// Client to access password manager functionality.
public protocol SudoPasswordManagerClient: class {

    /// Checks if the password manager is registered.
    /// - Parameter completion: Completion hander to return registration result.
    func getRegistrationStatus(completion: @escaping (Result<PasswordManagerRegistrationStatus, Error>) -> Void)

    /// Registers with the service.
    /// - Parameters:
    ///   - masterPassword: The master password that will be used to secure vaults.
    ///   - completion: Completion handler called when registration is finished.
    ///   If successfull the password manager will be unlocked.
    ///   If the user is already registered an error will be returned.
    func register(masterPassword: String, completion: @escaping (Result<Void, Error>) -> Void)

    /// Returns the secret code needed to bootstrap a new device.
    /// This is part of a rescue kit and should be backed up in a secure location.
    func getSecretCode() -> String?

    /// Locks the password manager.
    /// If the password manager hasn't been registered, or the secret code is missing, this function is a noop.
    func lock()

    /// Unlocks the password manager.
    /// - Parameters:
    ///   - masterPassword: master password of the password manager
    ///   - completion: If successfull, the password manager will be unlocked, otherwise an error if one occured.
    func unlock(masterPassword: String, secretCode: String?, completion: @escaping (Result<Void, Error>) -> Void)

    /// Removes all keys and any cached data associated with this client.
    /// A rescue kit should be generated prior to reseting as the secret code will be removed.
    /// This could lead to loss of data.
    func reset() throws

    /// Deregisters the vault user associated with this client.
    /// - Parameter completion: The completion handler to invoke to pass the deregistered user ID or error.
    func deregister(completion: @escaping (Result<String, Error>) -> Void)

    /// Checks if the vault is locked or not
    /// - Returns: True if the vault is unlocked, otherwise false.
    func isLocked() -> Bool

    /// Creates a new vault on the service. Requires password manager to be registered and unlocked.
    /// - Parameters:
    ///   - sudoId: Sudo ID that will own the vault.
    ///   - completion: Returns the vault, or an error if one occured.
    func createVault(sudoId: String, completion: @escaping (Result<Vault, Error>) -> Void )

    /// Fetches all vaults
    /// - Parameters:
    ///   - completion: completion handler that returns all vaults, or an error if one occured.
    func listVaults(completion: @escaping (Result<[Vault], Error>) -> Void)

    /// Fetches the vault with the specifided id. Requires password manager to be registered and unlocked.
    /// - Parameters:
    ///   - id: id of the vault
    ///   - completion: completion handler that returns a vault matching the provided id, or an error if one occured.
    func getVault(withId id: String, completion: @escaping (Result<Vault?, Error>) -> Void)

    /// Deletes a vault. Does not require the password manager to be unlocked.
    /// - Parameters:
    ///   - id: The id of the vault to delete
    ///   - completion: Returns an error if one occured.
    func deleteVault(withId id: String, completion: @escaping (Result<Void, Error>) -> Void)

    /// Change the master password. Requires password manager to be registered and unlocked.
    /// - Parameters:
    ///   - currentPassword: The current password.
    ///   - newPassword: the new password.
    ///   - completion: Completion handler that returns an error if one occured.
    func changeMasterPassword(currentPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void)

    /// Asynchronously adds a new item to the vault. Requires password manager to be registered and unlocked.
    /// - Parameter newItem: The `ValtItem` item to add.
    /// - Parameter toVault: Vault to add item to.
    /// - Parameter completion: Completion handler that returns the vault items, or an error if one occured.
    /// - Returns: The id of the new item that was added
    /// - Throws: An error if the item cannot be added (e.g. vault locked).
    func add(item: VaultItem, toVault vault: Vault, completion: @escaping (Result<String, Error>) -> Void)

    /// Asynchronously returns the full list of credentials stored in the vault. Requires password manager to be registered and unlocked.
    /// - Parameter inVault: Vault to list items from
    /// - Parameter completion: Completion handler that returns the vault items, or an error if one occured.
    func listVaultItems(inVault vault: Vault, completion: @escaping (Result<[VaultItem], Error>) -> Void)

    /// Asynchronously returns a single item if the id can be found. Requires password manager to be registered and unlocked.
    /// - Parameter id: id of the item to search for
    /// - Parameter in: Vault to get the item from
    /// - Parameter completion: Completion handler that returns the requested item, if found.
    func getVaultItem(id: String, in vault: Vault, completion: @escaping (Result<VaultItem?, Error>) -> Void)

    /// Asynchronously updates a credential in the vault. Requires password manager to be registered and unlocked.
    /// - Parameter credential: The item to update
    /// - Parameter from: vault to update item in.
    /// - Parameter completion: Completion handler when the update succeeds or fails.
    /// - Throws: An error if the item cannot be updated (e.g. vault locked)
    func update(item: VaultItem, in vault: Vault, completion: @escaping (Result<Void, Error>) -> Void)

    /// Asynchronously removes the vault item with the specified id. Requires password manager to be registered and unlocked.
    /// - Parameter id: id of the item to remove.
    /// - Parameter from: vault to remove item from.
    /// - Parameter completion: Completion handler when the removal succeeds or fails.
    /// - Throws: An error if the item cannot be updated (e.g. vault locked)
    func removeVaultItem(id: String, from vault: Vault, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Creates a Rescue Kit PDF with the user's secret code using the default template.
    ///
    /// - Returns: A Rescue Kit PDF with the secret code. Nil If the template image isn't found in the SDK bundle.
    func renderRescueKit() -> PDFDocument?

    /// Creates a Rescue Kit PDF with the user's secret code from the provided template.
    /// - Parameter templatePDF: An optional template image to use instead of the default.
    /// - Returns: A Rescue Kit PDF with the secret code.
    func renderRescueKit(templatePDF: PDFDocument) -> PDFDocument?

    /// Fetches the list of [Entitlement] that indicates the resources the user is entitled to use.
    /// - Parameter completion: handler called when fetching the entitlements succeeds or fails.
    func getEntitlement(completion: @escaping (Result<[Entitlement], Error>) -> Void)

    /// Fetches the current [EntitlementState] which includes information about how many entitlements have been consumed.
    /// - Parameter completion: Completion handler when fetching the current entitlement state succeeds or fails. An empty list indicates no entitlements have been consumed.
    func getEntitlementState(completion: @escaping (Result<[EntitlementState], Error>) -> Void)
}
