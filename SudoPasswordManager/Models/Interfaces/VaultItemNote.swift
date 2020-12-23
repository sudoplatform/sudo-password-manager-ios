//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// SecureField provider either provides a plain text value or ciphertext along with a function that decrypts it.
enum SecureFieldValue {
    /// Secure field is a plaintext value. No decryption required
    case plainText(String)

    /// Secure field is stored as ciphertext with the required decryption function
    case cipherText(String, () throws -> String)

    func reveal() throws -> String {
        switch self {
        case .plainText(let text): return text
        case .cipherText(_, let revealFunction): return try revealFunction()
        }
    }
}

/// Represents a note for items in the vault
public class VaultItemNote {

    /// - Returns: the clear text note
    /// - Throws: An error if the note cannot be displayed, e.g. if the password manager is locked.
    public func getValue() throws -> String {
        return try value.reveal()
    }

    let value: SecureFieldValue

    init(value: SecureFieldValue) {
        self.value = value
    }

    public init(value: String) {
        self.value = .plainText(value)
    }
}
