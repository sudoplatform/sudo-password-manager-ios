//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data to represent the current Entitlement State for Password Manager
public struct EntitlementState {
    /// Name of the Entitlement State
    public var name: Name

    public var sudoId: String
    
    /// The entitlement's limit
    public var limit: Int
    
    /// The current value for the entitlement
    public var value: Int
    
    /// Enum that represents the different type of entitlements available
    public enum Name: String {
        /// The max vaults entitled per sudo
        case maxVaultPerSudo
    }
    
}
