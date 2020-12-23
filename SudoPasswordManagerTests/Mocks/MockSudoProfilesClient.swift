//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoProfiles

/// Protocol encapsulating a library functions for managing Sudos in the Sudo service.
public class MockSudoProfilesClient: SudoProfilesClient {

    public func createSudo(sudo: Sudo, completion: @escaping (CreateSudoResult) -> Void) throws {

    }

    public func updateSudo(sudo: Sudo, completion: @escaping (UpdateSudoResult) -> Void) throws {

    }

    public func deleteSudo(sudo: Sudo, completion: @escaping (ApiResult) -> Void) throws {

    }


    var listSudosResult: ListSudosResult = ListSudosResult.success(sudos: [])
    public func listSudos(option: ListOption, completion: @escaping (ListSudosResult) -> Void) throws {
        completion(listSudosResult)
    }

    public func redeem(token: String, type: String, completion: @escaping (RedeemResult) -> Void) throws {

    }

    var getOutstandingRequestsCountCalled = false
    var getOutstandingRequestsCountResult = 0
    public func getOutstandingRequestsCount() -> Int {
        getOutstandingRequestsCountCalled = true
        return getOutstandingRequestsCountResult
    }

    public func reset() throws {

    }

    public func subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) throws {

    }

    public func subscribe(id: String, subscriber: SudoSubscriber) throws {

    }

    public func unsubscribe(id: String, changeType: SudoChangeType) {

    }

    public func unsubscribeAll() {

    }

    var getOwnershipProofCalled = false
    var getOwnershipProofParamSudo: Sudo?
    var getOwnershipProofParamAudience: String?
    var getOwnershipProofError: Error?
    var getOwnershipProofResult: GetOwnershipProofResult = .success(jwt: "")
    public func getOwnershipProof(sudo: Sudo, audience: String, completion: @escaping (GetOwnershipProofResult) -> Void) throws {
        getOwnershipProofCalled = true
        getOwnershipProofParamSudo = sudo
        getOwnershipProofParamAudience = audience
        if let e = getOwnershipProofError { throw e }
        completion(getOwnershipProofResult)
    }
}
