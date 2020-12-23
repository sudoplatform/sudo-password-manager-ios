//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CommonCrypto
import Security

extension Data {

    /// Hexadecimal string representation of `Data` object.
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined().uppercased()
    }

    /// Converts a hex string `Data`
    /// - Parameter string: The input string. Odd lenth strings are padded with a 0.
    /// - Returns: The hex string as data, or nil iff the string contains non hex characters
    init?(hexdecimalString string: String) {
        // Pad the string if needed
        var hexString = string
        if !hexString.count.isEven { hexString = "0" + hexString }

        // Convert each element to an integer quartet.
        let elementsAsHexBytes = hexString.compactMap({$0.hexDigitValue})

        // Check if the input had non-hex characters
        guard elementsAsHexBytes.count == hexString.count else { return nil }

        // Chunk into pairs and concat the high and low bits to make a single byte.
        let bytes: [UInt8] = elementsAsHexBytes.chunked(into: 2).map({ hexPair in
            // shift the 1st part over by 4 and combine with the 2nd half
            return UInt8((hexPair[0] << 4) + hexPair[1])
        })

        // convert UInt8 array to data
        self.init(bytes)
    }

    func sha1Hash() -> Data {
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(self.count), &buffer)
        }
        return Data(buffer)
    }
}
