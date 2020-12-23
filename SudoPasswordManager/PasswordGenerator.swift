//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import zxcvbn_ios

public enum PasswordStrength {
    case veryWeak
    case weak
    case moderate
    case strong
    case veryStrong
}

/// Generate a password
///
/// - Parameter length: The number of characters in the generated password. Must be >= 6
/// - Parameter allowUppercase: Whether the password should contain at least one uppercase letter (O and I excluded)
/// - Parameter allowLowercase: Whether the password should contain at least one lowercase letter (o and l excluded)
/// - Parameter allowNumbers: Whether the password should contain at least one number (0 and 1 excluded)
/// - Parameter allowSymbols: Whether the password should contain at least one of the symbols "!?@*._-"
/// - Returns: A string of the newly generated password
public func generatePassword(length: Int = 20,
                             allowUppercase: Bool = true,
                             allowLowercase: Bool = true,
                             allowNumbers: Bool = true,
                             allowSymbols: Bool = true) -> String {
    // initialize a cryptographically-secure random number generator
    var secureRandom = SecureRandomNumberGenerator()

    // default to all characters allowed if all are toggled off
    var allAllowed = false
    if !allowUppercase && !allowLowercase && !allowNumbers && !allowSymbols {
        allAllowed = true
    }

    // add possible characters excluding ambiguous characters `oO0lI1`
    let uppercase = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    let lowercase = "abcdefghijkmnpqrstuvwxyz"
    let numbers = "23456789"
    let symbols = "!?@*._-"

    var allPossibleCharacters = ""
    var password = ""
    if allowUppercase || allAllowed {
        allPossibleCharacters += uppercase
        // add one character from this set to ensure there's at least one
        password += String(uppercase.randomElement(using: &secureRandom)!)
    }
    if allowLowercase || allAllowed {
        allPossibleCharacters += lowercase
        // add one character from this set to ensure there's at least one
        password += String(lowercase.randomElement(using: &secureRandom)!)
    }
    if allowNumbers || allAllowed {
        allPossibleCharacters += numbers
        // add one character from this set to ensure there's at least one
        password += String(numbers.randomElement(using: &secureRandom)!)
    }
    if allowSymbols || allAllowed {
        allPossibleCharacters += symbols
        // add one character from this set to ensure there's at least one
        password += String(symbols.randomElement(using: &secureRandom)!)
    }

    // restrict length to greater than or equal to 6
    let finalLength = max(length, 6)

    // generate password
    for _ in 0...(finalLength - password.count - 1) {
        let character = String(allPossibleCharacters.randomElement(using: &secureRandom)!)
        password += character
    }

    // shuffle the password so it doesn't always start with uppercase->lowercase->etc..
    return String(password.shuffled(using: &secureRandom))
}

/// Calculate strength of a password
///
/// - Parameter password: The password string to calculate
/// - Returns: A `PasswordStrength` indicating the strength of the passed in password
public func calculateStrength(of password: String) -> PasswordStrength {
    let xcv = DBZxcvbn()
    let score = xcv.passwordStrength(password)?.score ?? 0
    switch score {
    case 0:
        return .veryWeak
    case 1:
        return .weak
    case 2:
        return .moderate
    case 3:
        return .strong
    case 4:
        return .veryStrong
    default:
        return .veryWeak
    }
}
