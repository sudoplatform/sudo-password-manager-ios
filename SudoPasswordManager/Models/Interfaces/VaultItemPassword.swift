//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a vault password plus the date it was created.
public class VaultItemPassword {
    /// created
    public let created: Date

    /// when this item was replaced
    internal(set) public var replaced: Date?

    /// Fetches the password value from the vault store. Passwords are stored in memory as cipher-text as an added layer of security.
    /// - Returns: the clear text password
    /// - Throws: An error if the password cannot be displayed, e.g. if the password manager is locked.
    public func getValue() throws -> String {
        return try value.reveal()
    }

    let value: SecureFieldValue

    init(value: SecureFieldValue, created: Date, replaced: Date?) {
        self.value = value
        self.created = created
        self.replaced = replaced
    }

    public init(value: String) {
        self.value = .plainText(value)
        self.created = Date()
        self.replaced = nil
    }
}
