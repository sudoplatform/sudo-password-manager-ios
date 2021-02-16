//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Reference to a vault. Returned from authenticated calls
///
public class Vault {
    /// ID of the vault
    internal(set) public var id: String

    /// When the vault was created
    public let createdAt: Date

    /// When the vault was last modified.
    public let updatedAt: Date

    public let owner: String

    public let owners: [VaultOwner]

    public init(id: String, owner: String, owners: [VaultOwner], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.owner = owner
        self.owners = owners
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func belongsToSudo(id: String) -> Bool {
        // Look for the "sudoplatform.sudoservice" owner and sudo id.
        return self.owners.contains(where: {$0.id == id && $0.issuer == "sudoplatform.sudoservice"})
    }
}

public class VaultOwner {
    public let id: String
    public let issuer: String

    public init(id: String, issuer: String) {
        self.id = id
        self.issuer = issuer
    }
}
