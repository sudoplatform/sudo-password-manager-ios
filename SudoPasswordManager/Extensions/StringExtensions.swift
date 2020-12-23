//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension String {

    /// Extracts capture groups from a string using a regex pattern
    /// - Parameter pattern: the regex paturn to use for the capture groups
    /// - Returns: A list of matches and the groups captured.
    func groupedUsingRegex(pattern: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))

        return matches.compactMap { match in

            // Starting at 1 is odd, but the docs say that the first index contains the range of the entire match
            // and the first capture group starts at 1. see https://developer.apple.com/documentation/foundation/nsregularexpression
            guard match.numberOfRanges > 1 else { return [] }

            return (1..<match.numberOfRanges).compactMap {
                // get the capture group NSRange and convert to Range<String.index>
                Range(match.range(at: $0), in: self)
            }
            .map {
                // Get the substrings
                String(self[$0])
            }
        }
    }
}
