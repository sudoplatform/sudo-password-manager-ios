//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Array {
    /// A swift implementation of Ruby chuncked function.
    func chunked(into sizes: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: sizes).map { index in
            let sliceStart = self.startIndex.advanced(by: index)
            let sliceEnd = Swift.min(sliceStart.advanced(by: sizes), self.count)
            return Array(self[sliceStart..<sliceEnd])
        }
    }
}

extension BinaryInteger {
    // The swift team rejected this extension in favor of `isMutiple`, but you deserve nice things.
    var isEven: Bool {
        return self.isMultiple(of: 2)
    }
}
