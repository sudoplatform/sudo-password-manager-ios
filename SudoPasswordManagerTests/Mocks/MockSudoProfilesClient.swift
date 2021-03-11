//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoProfiles

func runAfterDelayIfPresent(delay: TimeInterval?, action: @escaping () -> Void) {
    if let delay = delay {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    } else {
        action()
    }
}

public class MockSudoProfilesClient: SudoProfilesClient {

    var createSudoCalled = false
    var createSudoCallCount = 0
    var createSudoParameters: (sudo: Sudo, Void)?
    var createSudoParametersList: [(sudo: Sudo, Void)] = []
    var createSudoCompletionResult: (Swift.Result<Sudo, Error>)?
    var createSudoCompletionDelay: TimeInterval?
    var createSudoError: Error?

    public func createSudo(sudo: Sudo, completion: @escaping (Swift.Result<Sudo, Error>) -> Void) throws {
        createSudoCalled = true
        createSudoCallCount += 1
        createSudoParameters = (sudo, ())
        createSudoParametersList.append((sudo, ()))
        if let result = createSudoCompletionResult {
            runAfterDelayIfPresent(delay: createSudoCompletionDelay) {
                completion(result)
            }
        }
        if let error = createSudoError {
            throw error
        }
    }

    var updateSudoCalled = false
    var updateSudoCallCount = 0
    var updateSudoParameters: (sudo: Sudo, Void)?
    var updateSudoParametersList: [(sudo: Sudo, Void)] = []
    var updateSudoCompletionResult: Swift.Result<Sudo,Error>?
    var updateSudoCompletionDelay: TimeInterval?
    var updateSudoError: Error?

    public func updateSudo(sudo: Sudo, completion: @escaping (Swift.Result<Sudo, Error>) -> Void) throws {
        updateSudoCalled = true
        updateSudoCallCount += 1
        updateSudoParameters = (sudo, ())
        updateSudoParametersList.append((sudo, ()))
        if let result = updateSudoCompletionResult {
            runAfterDelayIfPresent(delay: updateSudoCompletionDelay) {
                completion(result)
            }
        }
        if let error = updateSudoError {
            throw error
        }
    }

    var deleteSudoCalled = false
    var deleteSudoCallCount = 0
    var deleteSudoParameters: (sudo: Sudo, Void)?
    var deleteSudoParametersList: [(sudo: Sudo, Void)] = []
    var deleteSudoCompletionResult: Swift.Result<Void, Error>?
    var deleteSudoCompletionDelay: TimeInterval?
    var deleteSudoError: Error?

    public func  deleteSudo(sudo: Sudo, completion: @escaping (Swift.Result<Void, Error>) -> Void) throws {
        deleteSudoCalled = true
        deleteSudoCallCount += 1
        deleteSudoParameters = (sudo, ())
        deleteSudoParametersList.append((sudo, ()))
        if let result = deleteSudoCompletionResult {
            runAfterDelayIfPresent(delay: deleteSudoCompletionDelay) {
                completion(result)
            }
        }
        if let error = deleteSudoError {
            throw error
        }
    }

    var listSudosCalled = false
    var listSudosCallCount = 0
    var listSudosParameters: (option: ListOption, Void)?
    var listSudosParametersList: [(option: ListOption, Void)] = []
    var listSudosCompletionResult: (Swift.Result<[Sudo],Error>)?
    var listSudosCompletionDelay: TimeInterval?
    var listSudosError: Error?

    public func  listSudos(option: ListOption, completion: @escaping (Swift.Result<[Sudo], Error>) -> Void) throws {
        listSudosCalled = true
        listSudosCallCount += 1
        listSudosParameters = (option, ())
        listSudosParametersList.append((option, ()))
        if let result = listSudosCompletionResult {
            runAfterDelayIfPresent(delay: listSudosCompletionDelay) {
                completion(result)
            }
        }
        if let error = listSudosError {
            throw error
        }
    }

    var redeemCalled = false
    var redeemCallCount = 0
    var redeemParameters: (token: String, type: String)?
    var redeemParametersList: [(token: String, type: String)] = []
    var redeemCompletionResult: Swift.Result<[Entitlement], Error>?
    var redeemCompletionDelay: TimeInterval?
    var redeemError: Error?

    public func  redeem(token: String, type: String, completion: @escaping (Swift.Result<[Entitlement], Error>) -> Void) throws {
        redeemCalled = true
        redeemCallCount += 1
        redeemParameters = (token, type)
        redeemParametersList.append((token, type))
        if let result = redeemCompletionResult {
            runAfterDelayIfPresent(delay: redeemCompletionDelay) {
                completion(result)
            }
        }
        if let error = redeemError {
            throw error
        }
    }

    var getOutstandingRequestsCountCalled = false
    var getOutstandingRequestsCountCallCount = 0
    var getOutstandingRequestsCountResult: Int! = 0

    public func  getOutstandingRequestsCount() -> Int {
        getOutstandingRequestsCountCalled = true
        getOutstandingRequestsCountCallCount += 1
        return getOutstandingRequestsCountResult
    }

    var resetCalled = false
    var resetCallCount = 0
    var resetError: Error?

    public func  reset() throws {
        resetCalled = true
        resetCallCount += 1
        if let error = resetError {
            throw error
        }
    }

    var subscribeIdCalled = false
    var subscribeIdCallCount = 0
    var subscribeIdParameters: (id: String, changeType: SudoChangeType, subscriber: SudoSubscriber)?
    var subscribeIdParametersList: [(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber)] = []
    var subscribeIdError: Error?

    public func  subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) throws {
        subscribeIdCalled = true
        subscribeIdCallCount += 1
        subscribeIdParameters = (id, changeType, subscriber)
        subscribeIdParametersList.append((id, changeType, subscriber))
        if let error = subscribeIdError {
            throw error
        }
    }

    var subscribeCalled = false
    var subscribeCallCount = 0
    var subscribeParameters: (id: String, subscriber: SudoSubscriber)?
    var subscribeParametersList: [(id: String, subscriber: SudoSubscriber)] = []
    var subscribeError: Error?

    public func  subscribe(id: String, subscriber: SudoSubscriber) throws {
        subscribeCalled = true
        subscribeCallCount += 1
        subscribeParameters = (id, subscriber)
        subscribeParametersList.append((id, subscriber))
        if let error = subscribeError {
            throw error
        }
    }

    var unsubscribeIdCalled = false
    var unsubscribeIdCallCount = 0
    var unsubscribeIdParameters: (id: String, changeType: SudoChangeType)?
    var unsubscribeIdParametersList: [(id: String, changeType: SudoChangeType)] = []

    public func  unsubscribe(id: String, changeType: SudoChangeType) {
        unsubscribeIdCalled = true
        unsubscribeIdCallCount += 1
        unsubscribeIdParameters = (id, changeType)
        unsubscribeIdParametersList.append((id, changeType))
    }

    var unsubscribeCalled = false
    var unsubscribeCallCount = 0
    var unsubscribeParameters: (id: String, Void)?
    var unsubscribeParametersList: [(id: String, Void)] = []

    public func  unsubscribe(id: String) {
        unsubscribeCalled = true
        unsubscribeCallCount += 1
        unsubscribeParameters = (id, ())
        unsubscribeParametersList.append((id, ()))
    }

    var unsubscribeAllCalled = false
    var unsubscribeAllCallCount = 0

    public func  unsubscribeAll() {
        unsubscribeAllCalled = true
        unsubscribeAllCallCount += 1
    }

    var getOwnershipProofCalled = false
    var getOwnershipProofCallCount = 0
    var getOwnershipProofParameters: (sudo: Sudo, audience: String)?
    var getOwnershipProofParametersList: [(sudo: Sudo, audience: String)] = []
    var getOwnershipProofCompletionResult: GetOwnershipProofResult?
    var getOwnershipProofCompletionDelay: TimeInterval?
    var getOwnershipProofError: Error?

    public func  getOwnershipProof(sudo: Sudo, audience: String, completion: @escaping (GetOwnershipProofResult) -> Void) throws {
        getOwnershipProofCalled = true
        getOwnershipProofCallCount += 1
        getOwnershipProofParameters = (sudo, audience)
        getOwnershipProofParametersList.append((sudo, audience))
        if let result = getOwnershipProofCompletionResult {
            runAfterDelayIfPresent(delay: getOwnershipProofCompletionDelay) {
                completion(result)
            }
        }
        if let error = getOwnershipProofError {
            throw error
        }
    }

    var generateEncryptionKeyCalled = false
    var generateEncryptionKeyCallCount = 0
    var generateEncryptionKeyError: Error?
    var generateEncryptionKeyResult: String! = ""

    public func  generateEncryptionKey() throws -> String {
        generateEncryptionKeyCalled = true
        generateEncryptionKeyCallCount += 1
        if let error = generateEncryptionKeyError {
            throw error
        }
        return generateEncryptionKeyResult
    }

    var getSymmetricKeyIdCalled = false
    var getSymmetricKeyIdCallCount = 0
    var getSymmetricKeyIdError: Error?
    var getSymmetricKeyIdResult: String!

    public func  getSymmetricKeyId() throws -> String? {
        getSymmetricKeyIdCalled = true
        getSymmetricKeyIdCallCount += 1
        if let error = getSymmetricKeyIdError {
            throw error
        }
        return getSymmetricKeyIdResult
    }

    var importEncryptionKeysCalled = false
    var importEncryptionKeysCallCount = 0
    var importEncryptionKeysParameters: (keys: [EncryptionKey], currentKeyId: String)?
    var importEncryptionKeysParametersList: [(keys: [EncryptionKey], currentKeyId: String)] = []
    var importEncryptionKeysError: Error?

    public func  importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws {
        importEncryptionKeysCalled = true
        importEncryptionKeysCallCount += 1
        importEncryptionKeysParameters = (keys, currentKeyId)
        importEncryptionKeysParametersList.append((keys, currentKeyId))
        if let error = importEncryptionKeysError {
            throw error
        }
    }

    var exportEncryptionKeysCalled = false
    var exportEncryptionKeysCallCount = 0
    var exportEncryptionKeysError: Error?
    var exportEncryptionKeysResult: [EncryptionKey]! = []

    public func  exportEncryptionKeys() throws -> [EncryptionKey] {
        exportEncryptionKeysCalled = true
        exportEncryptionKeysCallCount += 1
        if let error = exportEncryptionKeysError {
            throw error
        }
        return exportEncryptionKeysResult
    }
}
