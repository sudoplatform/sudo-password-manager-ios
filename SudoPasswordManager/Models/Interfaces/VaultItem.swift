//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Vault Data main interface.
/// For future proofing, all vault data structures will at least support
/// this interface.
public class VaultItem {

    /// unique id of this item
    public let id: String

    /// Time created. Unix Time (seconds since epoch)
    public let createdAt: Date

    /// Time created. Unix Time (seconds since epoch)
    public let updatedAt: Date

    init(id: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
