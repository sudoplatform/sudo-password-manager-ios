//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Security

struct SecureRandomNumberGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        var result: UInt64 = 0
        precondition(
            SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt64>.size, &result) == errSecSuccess,
            "SudoPasswordManager.SecureRandomNumberGenerator: SecRandomCopyBytes failed"
        )
        return result
    }
}
