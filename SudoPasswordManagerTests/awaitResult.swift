//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Helper function to avoid a lot of async completion block boilerplate within unit tests and the required expection / waitForExpectation calls.
///
/// Warning: Do not use this in production code.  This will block whatever thread it was called on which is fine for unit tests.
///
func awaitResult<T, E>(_ action: ((@escaping (Result<T, E>) -> Void) -> Void)) -> Result<T, E> {
    let group = DispatchGroup()
    group.enter()
    var result: Result<T, E>!
    action({ _result in
        result = _result
        group.leave()
    })
    _ = group.wait(timeout: DispatchTime.now() + 10)
    return result
}
