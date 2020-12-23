//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Provides functions to standardize the master password provided as input to password manager client functions
struct MasterPasswordTransformer {
    let userProvidedValue: String

    // Trims whitespace and normalizes the string to NFKD
    func standardize() -> String {
        return userProvidedValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .decomposedStringWithCompatibilityMapping
    }

    func data() -> Data? {
        return standardize().data(using: .utf8)
    }
}
