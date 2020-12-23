//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements

class MockSudoEntitlementsClient: SudoEntitlementsClient {

    var resetCalled: Bool = false
    var resetError: Error? = nil
    func reset() throws {
        resetCalled = true
        if let e = resetError {
            throw e
        }
    }

    var getEntitlementsCalled: Bool = false
    var getEntitlementsError: Error? = nil
    var getEntitlementsReturn: EntitlementsSet? = nil
    func getEntitlements(completion: @escaping ClientCompletion<EntitlementsSet?>) {
        getEntitlementsCalled = true
        if let e = getEntitlementsError {
            completion(.failure(e))
        }
        completion(.success(getEntitlementsReturn))
    }

    var redeemEntitlementsCalled: Bool = false
    var redeemEntitlementsError: Error? = nil
    var redeemEntitlementsReturn: EntitlementsSet = EntitlementsSet(name: "", description: nil, entitlements: [], version: 0, created: Date(), updated: Date())
    func redeemEntitlements(completion: @escaping ClientCompletion<EntitlementsSet>) {
        redeemEntitlementsCalled = true
        if let e = redeemEntitlementsError {
            completion(.failure(e))
        }
        completion(.success(redeemEntitlementsReturn))
    }
}
