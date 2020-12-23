//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represented the full set of credentials for a service.
public class VaultLogin: VaultItem {

    /// Username for the servivce
    public var user: String?

    /// URL or domain of the service.
    public var url: String?

    /// Name of this item
    public var name: String

    /// Space to store notes about the service.
    public var notes: VaultItemNote?

    /// Password for the service
    public var password: VaultItemPassword? {
        willSet {
            if let oldValue = password {
                oldValue.replaced = Date()
                self.previousPasswords.append(oldValue)
            }
        }
    }

    /// A list of previous passwords used for this service.  Currently contains a complete list of all previously saved passwords.
    private(set) public var previousPasswords: [VaultItemPassword]

    init(id: String, createdAt: Date, updatedAt: Date, user: String?, url: String?, name: String, notes: VaultItemNote?, password: VaultItemPassword?, previousPasswords: [VaultItemPassword]) {
        self.user = user
        self.url = url
        self.name = name
        self.notes = notes
        self.password = password
        self.previousPasswords = previousPasswords
        super.init(id: id, createdAt: createdAt, updatedAt: updatedAt)
    }

    convenience init(user: String?, url: String?, name: String, notes: VaultItemNote?, password: VaultItemPassword?, previousPasswords: [VaultItemPassword]) {
        let id = UUID().uuidString
        let now = Date()
        self.init(id: id, createdAt: now, updatedAt: now, user: user, url: url, name: name, notes: notes, password: password, previousPasswords: previousPasswords)
    }

    public convenience init(user: String?, url: String?, name: String, notes: VaultItemNote?, password: VaultItemPassword?) {
        self.init(user: user, url: url, name: name, notes: notes, password: password, previousPasswords: [])
    }
}
