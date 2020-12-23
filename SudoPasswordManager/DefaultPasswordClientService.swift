//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager
import CommonCrypto
import SudoLogging
import SudoUser
import SudoSecureVault
import SudoProfiles
import SudoEntitlements

class DefaultPasswordClientService: PasswordClientService {

    let secureVaultClient: SudoSecureVaultClient
    let sudoUserClient: SudoUserClient
    let sudoProfilesClient: SudoProfilesClient
    let entitlementsClient: SudoEntitlementsClient

    let keyManager: PasswordManagerKeyManager

    init(client: SudoSecureVaultClient,
         sudoUserClient: SudoUserClient,
         sudoProfilesClient: SudoProfilesClient,
         entitlementsClient: SudoEntitlementsClient) {
        self.secureVaultClient = client
        self.sudoUserClient = sudoUserClient
        self.sudoProfilesClient = sudoProfilesClient
        self.entitlementsClient = entitlementsClient

        self.keyManager = DefaultPasswordManagerKeyManager(userClient: sudoUserClient)
    }

    func getUserSubject() -> String? {
        do {
            return try self.sudoUserClient.getSubject()
        } catch {
            Logger.shared.debug("Failed to get sudo user subject: \(error)")
            return nil
        }
    }

    func getOwnershipProof(sudoId: String, completion: @escaping (Swift.Result<String, Error>) -> Void) {
        do {
            try self.sudoProfilesClient.getOwnershipProof(sudo: Sudo(id: sudoId), audience: "sudoplatform.secure-vault.vault") { (result) in
                switch result {
                case .success(let jwt):
                    completion(.success(jwt))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}

struct VaultCredentials {
    let masterPassword: Data
    let kdk: Data
}


struct UnlockedVaultSession {

    /// The users master password encrypted with a session key
    private let encryptedMasterPassword: Data

    /// The key manager responsible for storing the keys for the currently signed in user and performing crypto operations on session data
    private let keyManager: PasswordManagerKeyManager

    private let sessionKeyName = "sessionKey"

    init(masterPassword: Data, keyManager: PasswordManagerKeyManager) throws {
        // get the session key from the key manager, or create one ourself if this is the first run for this user.
        self.keyManager = keyManager


        /// Make sure we have a session key
        if try self.keyManager.getSymmetricKey(self.sessionKeyName) == nil {
            try self.keyManager.generateSymmetricKey(self.sessionKeyName, isExportable: false)
        }

        // Encrypte the master password before storing it
        self.encryptedMasterPassword = try self.keyManager.encryptWithSymmetricKey(self.sessionKeyName, data: masterPassword)
    }

    func getCredentials() throws -> VaultCredentials? {
        // decrypt master password using session key from keychain
        let masterPassword = try self.keyManager.decryptWithSymmetricKey(self.sessionKeyName, data: self.encryptedMasterPassword)

        // get KDK from keychain
        guard let kdk = try self.keyManager.getKeyDerivingKey() else {
            return nil
        }

        return VaultCredentials(masterPassword: masterPassword, kdk: kdk)
    }
}
