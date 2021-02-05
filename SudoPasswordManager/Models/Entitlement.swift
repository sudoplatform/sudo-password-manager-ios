//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data to represent the entitlements for Password Manager
public struct Entitlement {

    /// Name of the Entitlement
    public var name: Name

    /// The entitlement's limit
    public var limit: Int

    /// Enum that represents the different type of entitlements available
    public enum Name: String {
        /// The max vaults entitled per sudo
        case maxVaultPerSudo = "sudoplatform.vault.vaultMaxPerSudo"
    }
}

/// Data to represent the current Entitlement State for Password Manager
public struct EntitlementState {

    /// Name of the Entitlement
    public var name: Entitlement.Name

    /// Sudo which owns the entitlement consuming vaults
    public var sudoId: String
    
    /// The entitlement's limit
    public var limit: Int
    
    /// The current value of entitlements consumed.
    public var value: Int
}
