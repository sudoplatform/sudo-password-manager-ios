//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PDFKit
import SudoLogging
import SudoKeyManager
import SudoUser
import SudoSecureVault
import SudoProfiles
import SudoEntitlements

/// Define a type for the key deriving key
typealias KeyDerivingKey = Data

/// Defines the dependencies required for the password manager client. Also moves some state away from the client,
/// e.g. keys and data needs to be namespaced so it doesn't conflict with other users, but client doesn't need
/// to deal with that.
protocol PasswordClientService {
    /// Provides access to encrypted vaults
    var secureVaultClient: SudoSecureVaultClient { get }

    var sudoUserClient: SudoUserClient { get }

    var keyManager: PasswordManagerKeyManager { get }

    var sudoProfilesClient: SudoProfilesClient { get }

    var entitlementsClient: SudoEntitlementsClient { get }

    /// Gets the `subject` of the current logged in user.
    func getUserSubject() -> String?

    /// Gets the ownership proof of the specified sudo id for the password manager service audience
    func getOwnershipProof(sudoId: String, completion: @escaping (Swift.Result<String, Error>) -> Void)
}

public class DefaultPasswordManagerClient: PasswordManagerClient {

    // Handles all the service dependencies which needs to be passed in.
    let service: PasswordClientService

    // Logged in/out session data
    private var sessionData: UnlockedVaultSession?

    // Internal handling of vaults
    lazy var vaultStore: VaultStore = {
        return VaultStore()
    }()

    lazy var vaultFactory: VaultFactory = {
        return VaultFactory(client: self, keyManager: self.service.keyManager)
    }()

    var rescueKitGenerator: RescueKitGenerator {
        return RescueKitGenerator()
    }
    
    init(service: PasswordClientService) {
        self.service = service
    }

    // MARK: Registration / Unlocking

    public func getRegistrationStatus(completion: @escaping (Result<PasswordManagerRegistrationStatus, Error>) -> Void) {
        do {
            try self.service.secureVaultClient.isRegistered { [weak self] (registrationResult) in
                guard let self = self else { return }
                switch registrationResult {
                case .success(let isRegistered):
                    guard isRegistered else {
                        completion(.success(.notRegistered))
                        return
                    }
                    do {
                        if try self.service.keyManager.getKeyDerivingKey() != nil {
                            completion(.success(.registered))
                        } else {
                            completion(.success(.missingSecretCode))
                        }
                    } catch {
                        // This error could happen because we were unable to get get the user id namespace to look for the key.
                        if error is PasswordManagerError {
                            completion(.failure(error))
                        } else {
                            let error = PasswordManagerError.init(type: .security, underlyingError: error)
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
                }
            }
        } catch {
            completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
        }
    }

    public func register(masterPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {

        // The service expects type `Data` for the password.  We'll also want to do some trimming, possibly validation on
        // lenght.  This step makes sure we can proceed with the correct type and validation requirements.
        guard let passwordData = MasterPasswordTransformer(userProvidedValue: masterPassword).data() else {
            var error = PasswordManagerError(type: .invalidFormat)
            error.userInfo = [PasswordManagerError.UserInfoKey.debugDescription: "Failed to convert master password to Data."]
            completion(.failure(error))
            return
        }

        // Attempt to register.  This assumes registration status is .notRegistered and relies on the client to do the right thing
        // if we attempt to register twice with the same credentials.
        do {
            // We need to store the key before we register in case registration is sucessfull but we never recieved
            // the response (e.g. loss of network, app crash). On retry we should get a response that indicates registration
            // was sucessfull, so we need to make sure we still have the key derriving key.
            //
            // This also covers the case where the registration request never made it to the service befor this was interrupted
            // by fetching the key previously created.
            let key: KeyDerivingKey
            if let existingKey = try self.service.keyManager.getKeyDerivingKey() {
                key = existingKey
            } else {
                key = try self.service.keyManager.generateKeyDerivingKey()
                try self.service.keyManager.set(keyDerivingKey: key)
            }
            try self.service.secureVaultClient.register(key: key, password: passwordData) { (result) in
                guard case .failure(let error) = result else {
                    completion(.success(()))
                    return
                }

                completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error)))
            }
        } catch {
            completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error)))
        }
    }

    private func transformThrown(error: Error) -> PasswordManagerError {
        if let error = error as? PasswordManagerError {
            return error
        } else if error is SudoKeyManagerError {
            return PasswordManagerError(type: .security, underlyingError: error, userInfo: nil)
        } else {
            return PasswordManagerError(type: .unknown, underlyingError: error, userInfo: nil)
        }
    }

    public func getSecretCode() -> String? {
        guard let keyAsHex = try? self.service.keyManager.getKeyDerivingKey()?.hexString else {
            Logger.shared.debug("Missing key derriving key")
            return nil
        }

        return formatSecretCode(string: self.calculateSecretCodeSubscriberPrefix() + keyAsHex)
    }

    // Calculates the secret code subscriber prefix.  This is the first 5 characters of the user subscriber id hashed with sha1.
    // This could fail (unlikely), but shouldn't stop the secret code from being exported so as a backup a string of all zeros is returned.
    private func calculateSecretCodeSubscriberPrefix() -> String {
        let prefix = "00000"

        guard let subjectHash = self.service.getUserSubject()?.data(using: .utf8)?.sha1Hash().hexString else {
            Logger.shared.debug("Failed to get user subject when generating secret code")
            return prefix
        }

        let firstFiveCharacters = subjectHash.prefix(5)
        guard firstFiveCharacters.count == 5 else {
            return prefix
        }

        return String(firstFiveCharacters)
    }

    public func lock() {
        self.sessionData = nil
        self.vaultStore.removeAll()
    }

    public func unlock(masterPassword: String, secretCode: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        // The service expects type `Data` for the password.  We'll also want to do some trimming, possibly validation on
        // lenght.  This step makes sure we can proceed with the correct type and validation requirements.
        guard let passwordData = MasterPasswordTransformer(userProvidedValue: masterPassword).data() else {
            var error = PasswordManagerError(type: .invalidFormat)
            error.userInfo = [PasswordManagerError.UserInfoKey.debugDescription: "Failed to convert master password to Data."]
            completion(.failure(error))
            return
        }

        // Validate the user is signed in through SudoUser. Since the client might support multiple users our local data must be
        // checked against it.


        // validate if we need a new secret code or not
        // e.g. get secret code, compare, etc.
        var kdk: Data?
        do {
            kdk = try self.service.keyManager.getKeyDerivingKey()
        } catch {
            // This is being treated as an unrecoverable error case, however we could check the secret code passed in and see
            // if that will let us unlock the vault
            let error = PasswordManagerError(type: .invalidPasswordOrMissingSecretCode, underlyingError: error, userInfo: nil)
            completion(.failure(error))
            return
        }

        // Key can come from different places.  For clarity a switch statment makes it most clear
        // which path the key came from.
        switch (kdk, secretCode.flatMap { parseSecretCode(string: $0)}) {
        case (nil, nil):
            // No cached KDK or secret key provided
            let error = PasswordManagerError(type: .invalidPasswordOrMissingSecretCode, underlyingError: nil, userInfo: nil)
            completion(.failure(error))

        case (.some(let key), nil):
            // Cached KDK.  Should be most common case
            //unlockingKey = key
            self.validateCredentials(key: key, passwordData: passwordData, completion: completion)

        case (nil, .some(let key)):
            // No cached KDK, user provided it

            // validate the kdk the user passed in.
            self.validateCredentials(key: key, passwordData: passwordData, completion: completion)

        case (.some(let key), .some):
            // Cached KDK and user passed a new one in.
            self.validateCredentials(key: key, passwordData: passwordData, completion: completion)
        }
    }

    // Handles the work of unlocking the vault behind the public "unlock" function after the pasword and key have been fetched and validated.
    private func validateCredentials(key: KeyDerivingKey, passwordData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        // "unlock" the vault by downloading a list of vault which validates the key and password
        do {
            try self.service.secureVaultClient.listVaults(key: key, password: passwordData) { [weak self] (result) in
                guard let self = self else {return}
                switch result {
                case .success(let vaults):
                    // store vault data
                    self.vaultStore.importSecureVaults(vaults)

                    // store the key derriving key in the key store
                    do {
                        try self.service.keyManager.set(keyDerivingKey: key)
                    } catch {
                        // It's expected to catch errors here if the key already exists.
                        Logger.shared.debug("Failed to save key in keychain: \(error)")
                    }

                    let session =  try? UnlockedVaultSession(masterPassword: passwordData, keyManager: self.service.keyManager)
                    self.sessionData = session

                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
                    return
                }
            }
        } catch {
            completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
        }
    }

    public func reset() throws {
        self.lock()
        try self.service.secureVaultClient.reset()
        try self.service.keyManager.removeAllKeys()
    }

    public func deregister(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try self.service.secureVaultClient.deregister { (result) in
                // After deregister remove all keys and lock the vault to remove all data.
                if case .success(_) = result {
                    try? self.service.keyManager.removeAllKeys()
                    self.lock()
                }
                completion(result)
            }
        } catch {
            completion(.failure(error))
        }
    }

    public func isLocked() -> Bool {
        do {
            return try self.sessionData?.getCredentials() == nil
        } catch {
            return true
        }
    }

    // MARK: Vaults

    public func createVault(sudoId: String, completion: @escaping (Result<Vault, Error>) -> Void) {

        guard let credentials = (try? self.sessionData?.getCredentials()) else { completion(.failure(PasswordManagerError.vaultLocked)); return }


        do {
            // Ownership proof can be empty here because we arn't using it when we marshal the data.
            let newVault = VaultProxy(ownershipProof: "")

            // this should never throw because we are creating an empty vault object and converting it to json.
            // Check for it anyways to avoid a crash
            let blob = try VaultSchema.encodeVaultWithLatestSchema(vault: newVault)

            self.service.getOwnershipProof(sudoId: sudoId) { (result) in
                do {
                    // Rather than switch we can extract the value here and handle the failure in the catch block
                    // that is being used for other errors in this function.
                    let proof = try result.get()
                    try self.service.secureVaultClient.createVault(key: credentials.kdk,
                                                                   password: credentials.masterPassword,
                                                                   blob: blob,
                                                                   blobFormat: newVault.blobFormat.rawValue,
                                                                   ownershipProof: proof) { (result) in

                        switch result {
                        case .success(let vaultMetadata):
                            // Create a vault proxy from the meta data returned along with the vault data we created earlier.
                            let vaultData = VaultProxy(secureVaultId: vaultMetadata.id,
                                                       blobFormat: newVault.blobFormat,
                                                       createdAt: vaultMetadata.createdAt,
                                                       updatedAt: vaultMetadata.updatedAt,
                                                       version: vaultMetadata.version,
                                                       owner: vaultMetadata.owner,
                                                       owners: vaultMetadata.owners.map({return VaultProxy.VaultOwner.init(id: $0.id, issuer: $0.issuer)}),
                                                       vaultData: newVault.vaultData)

                            // Save the newly created vault to the store.
                            self.vaultStore.importVault(vaultData)

                            // Create a user visible object and return
                            let owners = vaultMetadata.owners.map({ VaultOwner(id: $0.id, issuer: $0.issuer)})
                            let vault = Vault(id: vaultMetadata.id, owner: vaultMetadata.owner, owners: owners, createdAt: vaultMetadata.createdAt, updatedAt: vaultMetadata.updatedAt)
                            completion(.success(vault))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } catch {
                    switch error {
                    case is SudoSecureVaultClientError:
                        completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
                    default:
                        completion(.failure(PasswordManagerError(type: .internal, underlyingError: error, userInfo: nil)))
                    }
                }
            }
        } catch {
            completion(.failure(PasswordManagerError.init(type: .internal, underlyingError: error)))
        }
    }

    public func listVaults(completion: @escaping (Result<[Vault], Error>) -> Void) {
        guard self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        // Currently assumes all vaults are downloaded when the vault is unlocked.  This ignores any errors that occur, or syncing.
        let proxies = self.vaultStore.listVaults()

        let vaults: [Vault] = proxies.map {
            let owners = $0.owners.map({ VaultOwner(id: $0.id, issuer: $0.issuer)})
            return Vault(id: $0.secureVaultId, owner: $0.owner, owners: owners, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
        }

        completion(.success(vaults))
    }

    public func getVault(withId id: String, completion: @escaping (Result<Vault?, Error>) -> Void) {
        guard self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        guard let proxy = self.vaultStore.getVault(withId: id) else {
            completion(.success(nil))
            return
        }

        let owners = proxy.owners.map({ VaultOwner(id: $0.id, issuer: $0.issuer)})
        completion(.success(Vault(id: proxy.secureVaultId, owner: proxy.owner, owners: owners, createdAt: proxy.createdAt, updatedAt: proxy.updatedAt)))
    }

    func update(vault: Vault, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionData = (try? self.sessionData?.getCredentials()) else { completion(.failure(PasswordManagerError.vaultLocked)); return }


        guard let vaultProxy = self.vaultStore.getVault(withId: vault.id) else {
            completion(.failure(PasswordManagerError.invalidVault)); return
        }

        // Get the vault data from the store and encode it.
        guard let vaultData = try? VaultSchema.encodeVaultWithLatestSchema(vault: vaultProxy) else {
            completion(.failure(PasswordManagerError.invalidVault)); return
        }

        do {
            try self.service.secureVaultClient.updateVault(key: sessionData.kdk,
                                                           password: sessionData.masterPassword,
                                                           id: vaultProxy.secureVaultId,
                                                           version: vaultProxy.version,
                                                           blob: vaultData,
                                                           blobFormat: vaultProxy.blobFormat.rawValue) { (result) in
                switch result {
                case .success(let metadata):
                    self.vaultStore.updateVault(with: metadata)
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
        }
    }

    public func deleteVault(withId id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try self.service.secureVaultClient.deleteVault(id: id) { result in
                switch result {
                case .success:
                    self.vaultStore.deleteVault(withId: id)
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
        }
    }

    public func changeMasterPassword(currentPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionData = (try? self.sessionData?.getCredentials()),
              self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        guard let current = MasterPasswordTransformer(userProvidedValue: currentPassword).data(),
            let newPasswordData = MasterPasswordTransformer(userProvidedValue: newPassword).data() else {
                completion(.failure(PasswordManagerError.invalidPasswordOrMissingSecretCode))
                return
        }

        do {
            try self.service.secureVaultClient.changeVaultPassword(key: sessionData.kdk, oldPassword: current, newPassword: newPasswordData) { (result) in
                switch result {
                case .success:
                    self.sessionData = try? UnlockedVaultSession(masterPassword: newPasswordData, keyManager: self.service.keyManager)
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
        }
    }

    // MARK: Vault Items

    public func add(item: VaultItem, toVault vault: Vault, completion: @escaping (Result<String, Error>) -> Void) {

        guard self.isLocked() == false else {
            completion(.failure(PasswordManagerError.vaultLocked))
            return
        }

        // get the vault key
        guard let vaultKey = (try? self.sessionData?.getCredentials())?.kdk else {
            completion(.failure(PasswordManagerError.vaultLocked))
            return
        }
        
        guard let login = item as? VaultLogin else {
            completion(.failure(PasswordManagerError.invalidFormat))
            return
        }

        do {
            let loginProxy = try self.vaultFactory.createVaultLoginProxy(from: login, vaultKey: vaultKey)
            try self.vaultStore.add(login: loginProxy, toVaultWithId: vault.id)

            // Update vault with the service.
            self.update(vault: vault) { (updateResult) in
                switch updateResult {
                case .success:
                    completion(.success(loginProxy.id))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            // This is the wrong error if the item couldn't be converted.  It's a format or encryption problem.
            completion(.failure(PasswordManagerError.invalidVault))
        }
    }

    public func listVaultItems(inVault vault: Vault, completion: @escaping (Result<[VaultItem], Error>) -> Void) {
        guard self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        // Get the internal data from the store
        guard let internalVault = self.vaultStore.getVault(withId: vault.id) else {
            completion(.success([]))
            return
        }

        guard let vaultKey = (try? self.sessionData?.getCredentials())?.kdk else {
            Logger.shared.debug("Invalid secure field key found")
            completion(.failure(PasswordManagerError.invalidVault))
            return
        }

        // Create a window into the internal data to return to the client.
        let vaultItems = internalVault.vaultData.login.map {
            return self.vaultFactory.createVaultLogin(from: $0, revealKey: vaultKey)
        }
        completion(.success(vaultItems))
    }

    public func getVaultItem(id: String, in vault: Vault, completion: @escaping (Result<VaultItem?, Error>) -> Void) {
        guard self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        // Get the internal data from the store
        guard let internalVault = self.vaultStore.getVault(withId: vault.id), let item = internalVault.vaultData.login.first(where: { $0.id == id }) else {
            completion(.success(nil))
            return
        }

        guard let vaultKey = (try? self.sessionData?.getCredentials())?.kdk else {
            Logger.shared.debug("Invalid secure field key found")
            completion(.failure(PasswordManagerError.vaultLocked))
            return
        }

        completion(.success(self.vaultFactory.createVaultLogin(from: item, revealKey: vaultKey)))
    }

    public func update(item: VaultItem, in vault: Vault, completion: @escaping (Result<Void, Error>) -> Void) {
        guard self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        // get the vault key
        guard let vaultKey = (try? self.sessionData?.getCredentials())?.kdk else {
            completion(.failure(PasswordManagerError.vaultLocked))
            return
        }
        
        guard let login = item as? VaultLogin else {
            completion(.failure(PasswordManagerError.invalidFormat))
            return
        }

        // Convert the `VaultLogin` to our vault store format
        do {
            let proxy = try self.vaultFactory.createVaultLoginProxy(from: login, vaultKey: vaultKey)
            try self.vaultStore.update(login: proxy, in: vault.id)

            // Update the vault with the service.
            self.update(vault: vault, completion: completion)
        } catch {
            completion(.failure(PasswordManagerError.invalidVault))
        }
    }

    public func removeVaultItem(id: String, from vault: Vault, completion: @escaping (Result<Void, Error>) -> Void) {
        guard self.isLocked() == false else { completion(.failure(PasswordManagerError.vaultLocked)); return }

        do {
            try self.vaultStore.removeVaultLogin(withId: id, vaultId: vault.id)

            // update the vault with the service
            self.update(vault: vault, completion: completion)
        } catch {
            completion(.failure(PasswordManagerError.invalidVault))
        }
    }
    
    // MARK: - Rescue Kit
    
    public func renderRescueKit() -> PDFDocument? {
        if let code = getSecretCode() {
            return rescueKitGenerator.generatePDF(with: code)
        }
        return nil
    }
    
    // MARK: - Entitlement State
    
    public func getEntitlementState(completion: @escaping (Result<[EntitlementState], Error>) -> Void) {
        DispatchQueue.init(label: "Entitlements").async {
            do {
                // We need to make multiple api calls to fetch different pieces so we can stich them all together to form
                // an entitlement.
                let group = DispatchGroup()

                // Get entitlements
                group.enter()
                var entitlementsList: [SudoEntitlements.Entitlement] = []
                var serviceError: Error?
                self.service.entitlementsClient.getEntitlements(completion: { (result) in
                    switch result {
                    case .success(let set):
                        entitlementsList = set?.entitlements ?? []
                    case .failure(let error):
                        serviceError = error
                    }
                    group.leave()
                })

                // Get vault metadata
                group.enter()
                var vaultMetadata: [VaultMetadata] = []
                try self.service.secureVaultClient.listVaultsMetadataOnly { (result) in
                    switch result {
                    case .success(let vaults):
                        vaultMetadata = vaults
                    case .failure(let error):
                        serviceError = PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)
                    }
                    group.leave()
                }

                // Get sudos
                group.enter()
                var sudoList: [Sudo] = []
                try self.service.sudoProfilesClient.listSudos(option: .remoteOnly, completion: { (result) in
                    switch result {
                    case .success(let sudos):
                        sudoList = sudos
                    case .failure(let cause):
                        serviceError = cause
                    }
                    group.leave()
                })

                group.wait()

                if let serviceError = serviceError {
                    completion(.failure(serviceError))
                    return
                }

                let states = self.calculateEntitlementStates(sudos: sudoList, entitlements: entitlementsList, vaultMetadata: vaultMetadata)
                completion(.success(states))
            } catch {
                completion(.failure(PasswordManagerError(type: .secureVaultService, underlyingError: error, userInfo: nil)))
            }
        }
    }

    func calculateEntitlementStates(sudos: [Sudo], entitlements: [SudoEntitlements.Entitlement], vaultMetadata: [VaultMetadata]) -> [EntitlementState] {

        guard let maxVaultsPerSudoEntitlement = entitlements.first(where: { $0.name == "sudoplatform.vault.vaultMaxPerSudo" }) else {
            return []
        }

        // Create a histogram(almost) of each sudo's vault count.
        // dictionary init(grouping) doesn't like optional keys.  I considered returning a trash key instead and then removing those items,
        // but that would limit the sudo id set of values, even arbitrarily.  The filter and force unwrap just makes the linter sad.
        let vaultsWithSudoId = vaultMetadata.filter({$0.sudoId != nil})
        let vaultsGroupedBySudoId: [String: [VaultMetadata]] = Dictionary.init(grouping: vaultsWithSudoId) { (aVault) in
            return aVault.sudoId!
        }

        var states: [EntitlementState] = []
        for sudoId in sudos.compactMap({return $0.id}) {
            let vaultCount = vaultsGroupedBySudoId[sudoId]?.count ?? 0
            states.append(EntitlementState(name: .maxVaultPerSudo, sudoId: sudoId, limit: maxVaultsPerSudoEntitlement.value, value: vaultCount))
        }

        return states
    }
}

extension VaultMetadata {
    var sudoId: String? {
        return self.owners.first(where: {$0.issuer == "sudoplatform.sudoservice"})?.id
    }
}
