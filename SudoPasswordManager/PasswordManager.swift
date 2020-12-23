//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager
import SudoUser
import SudoSecureVault
import SudoProfiles
import SudoEntitlements

/// Entry point to the password manager
public class PasswordManager {
    private let sudoUserClient: SudoUserClient
    private let vaultClient: SudoSecureVaultClient
    private let profilesClient: SudoProfilesClient
    private let entitlementsClient: SudoEntitlementsClient

    public init(sudoUserClient: SudoUserClient, vaultClient: SudoSecureVaultClient, profilesClient: SudoProfilesClient, entitlementsClient: SudoEntitlementsClient) {
        self.sudoUserClient = sudoUserClient
        self.vaultClient = vaultClient
        self.profilesClient = profilesClient
        self.entitlementsClient = entitlementsClient
    }

    public init(sudoUserClient: SudoUserClient, fileStorage: URL?) throws {
        self.sudoUserClient = sudoUserClient
        self.vaultClient = try DefaultSudoSecureVaultClient(sudoUserClient: self.sudoUserClient)
        self.entitlementsClient = try DefaultSudoEntitlementsClient(userClient: self.sudoUserClient)

        let storageURL = fileStorage ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.profilesClient = try DefaultSudoProfilesClient(sudoUserClient: self.sudoUserClient, blobContainerURL: storageURL)
    }

    /// Gets the password manager client.
    public func getClient() -> PasswordManagerClient {
        let service = DefaultPasswordClientService(client: self.vaultClient,
                                                   sudoUserClient: self.sudoUserClient,
                                                   sudoProfilesClient: self.profilesClient,
                                                   entitlementsClient: self.entitlementsClient)
        return DefaultPasswordManagerClient(service: service)
    }
}
