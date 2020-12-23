//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

let kdkCount = 32
let secretCodeSuffixCount = 5

func formatSecretCode(string: String) -> String? {
    guard string.count == kdkCount + secretCodeSuffixCount else { return nil }

    // 5-6-5-5-5-5-6 pattern - first 5 is user sub from SudoUser, rest is the kdk.
    let pattern = "5-6-5-5-5-5-6"
    var regex = ""

    // Using a string pattern and manually splitting it because it's easy to make mistakes translating it manually into the regex groups.
    // If the pattern changes we can more easily copy/paste the new pattern in.
    //
    // Walk each group and add the correct number of periods inside parenthesis to form the regex pattern.
    pattern.split(separator: "-").map({ Int($0)! }).forEach { (groupSize) in
        regex.append("(")
        regex.append(String.init(repeating: ".", count: groupSize))
        regex.append(")")
    }

    return string.groupedUsingRegex(pattern: regex).first?.joined(separator: "-")
}

func parseSecretCode(string: String) -> Data? {
    let hexstring = string.replacingOccurrences(of: "-", with: "")
    // Secret code is the last 32 digits of the code passed in.  We append (e.g. hash of user id) metadata to the front of the
    // secret code for support purposes.
    return Data(hexdecimalString: String(hexstring.suffix(32)))
}
