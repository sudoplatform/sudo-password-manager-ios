//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoSecureVault


open class MyMockSudoSecureVaultClient: SudoSecureVaultClient {

    public var version: String = "0"


    public var isRegisteredCalled = false
    public var isRegisteredError: Error?
    public var isRegisteredResult: Result<Bool, Error> = .success(false)
    open func isRegistered(completion: @escaping (Result<Bool, Error>) -> Void) throws {
        isRegisteredCalled = true
        if let error = isRegisteredError { throw error }
        completion(isRegisteredResult)
    }

    public var resetCalled = false
    public var resetError: Error?
    open func reset() throws {
        resetCalled = true
        if let e = resetError { throw e }
    }


    public var registerCalled = false
    public var registerParamKey: Data?
    public var registerParamPassword: Data?
    public var registerError: Error?
    public var registerResult: Result<String, Error> = .success("")
    open func register(key: Data,
                  password: Data,
                  completion: @escaping (Result<String, Error>) -> Void) throws {
        registerCalled = true
        registerParamKey = key
        registerParamPassword = password
        if let e = registerError { throw e }
        completion(registerResult)
    }


    public var getInitializationDataCalled = false
    public var getInitializationDataError: Error?
    public var getInitializationDataResult: Result<InitializationData?, Error> = .success(nil)
    open func getInitializationData(completion: @escaping (Result<InitializationData?, Error>) -> Void) throws {
        getInitializationDataCalled = true
        if let error = getInitializationDataError { throw error }
        completion(getInitializationDataResult)
    }


    public var deregisterCalled = false
    public var deregisterError: Error?
    public var deregisterResult: Result<String, Error> = .success("")
    open func deregister(completion: @escaping (Result<String, Error>) -> Void) throws {
        deregisterCalled = true
        if let error = deregisterError { throw error }
        completion(deregisterResult)
    }


    public var createVaultCalled = false
    public var createVaultParamKey: Data?
    public var createVaultParamPassword: Data?
    public var createVaultParamBlob: Data?
    public var createVaultParamBlobFormat: String?
    public var createVaultParamOwnershipProof: String?
    public var createVaultError: Error?
    public var createVaultResult: Result<VaultMetadata, Error> = .success(VaultMetadata(id: "1", owner: "2", version: 0, blobFormat: "3", createdAt: Date(), updatedAt: Date(), owners: []))
    open func createVault(
        key: Data,
        password: Data,
        blob: Data,
        blobFormat: String,
        ownershipProof: String,
        completion: @escaping (Result<VaultMetadata, Error>) -> Void
    ) throws {
        createVaultCalled = true
        createVaultParamKey = key
        createVaultParamPassword = password
        createVaultParamBlob = blob
        createVaultParamBlobFormat = blobFormat
        createVaultParamOwnershipProof = ownershipProof
        if let e = createVaultError { throw e }
        completion(createVaultResult)
    }

    public var updateVaultCalled = false
    public var updateVaultParamKey: Data?
    public var updateVaultParamPassword: Data?
    public var updateVaultParamBlob: Data?
    public var updateVaultParamBlobFormat: String?
    public var updateVaultError: Error?
    public var updateVaultResult: Result<VaultMetadata, Error> = .success(VaultMetadata(id: "1", owner: "2", version: 0, blobFormat: "3", createdAt: Date(), updatedAt: Date(), owners: []))
    open func updateVault(
        key: Data,
        password: Data,
        id: String,
        version: Int,
        blob: Data,
        blobFormat: String,
        completion: @escaping (Result<VaultMetadata, Error>) -> Void
    ) throws {
        updateVaultCalled = true
        updateVaultParamKey = key
        updateVaultParamPassword = password
        updateVaultParamBlob = blob
        updateVaultParamBlobFormat = blobFormat
        if let e = updateVaultError { throw e }
        completion(updateVaultResult)
    }

    public var deleteVaultCalled = false
    public var deleteVaultParamID: String?
    public var deleteVaultError: Error?
    public var deleteVaultResult: Result<VaultMetadata?, Error> = .success(nil)
    open func deleteVault(id: String, completion: @escaping (Result<VaultMetadata?, Error>) -> Void) throws {
        deleteVaultCalled = true
        deleteVaultParamID = id
        if let e = deleteVaultError { throw e }
        completion(deleteVaultResult)
    }


    public var getVaultCalled = false
    public var getVaultParamKey: Data?
    public var getVaultParamPassword: Data?
    public var getVaultParamId: String?
    public var getVaultError: Error?
    public var getVaultResult: Result<Vault?, Error> = .success(nil)
    open func getVault(
        key: Data,
        password: Data,
        id: String,
        completion: @escaping (Result<Vault?, Error>) -> Void
    ) throws {
        getVaultCalled = true
        getVaultParamKey = key
        getVaultParamPassword = password
        getVaultParamId = id
        if let e = getVaultError { throw e }
        completion(getVaultResult)
    }

    public var listVaultsCalled = false
    public var listVaultsParamKey: Data?
    public var listVaultsParamPassword: Data?
    public var listVaultsError: Error?
    public var listVaultsResult: Result<[Vault], Error> = .success([])
    open func listVaults(key: Data, password: Data, completion: @escaping (Result<[Vault], Error>) -> Void) throws {
        listVaultsCalled = true
        listVaultsParamKey = key
        listVaultsParamPassword = password
        if let e = listVaultsError { throw e }
        completion(listVaultsResult)
    }

    public var listVaultsMetadataOnlyCalled = false
    public var listVaultsMetadataOnlyError: Error?
    public var listVaultsMetadataOnlyResult: Result<[VaultMetadata], Error> = .success([])
    open func listVaultsMetadataOnly(completion: @escaping (Result<[VaultMetadata], Error>) -> Void) throws {
        listVaultsMetadataOnlyCalled = true
        if let e = listVaultsMetadataOnlyError { throw e }
        completion(listVaultsMetadataOnlyResult)
    }

    public var changeVaultPasswordCalled = false
    public var changeVaultPasswordParamKey: Data?
    public var changeVaultPasswordParamOldPassword: Data?
    public var changeVaultPasswordParamNewPassword: Data?
    public var changeVaultPasswordError: Error?
    public var changeVaultPasswordResult: Result<Void, Error> = .success(())
    open func changeVaultPassword(
        key: Data,
        oldPassword: Data,
        newPassword: Data,
        completion: @escaping (Result<Void, Error>) -> Void
    ) throws {
        changeVaultPasswordCalled = true
        changeVaultPasswordParamKey = key
        changeVaultPasswordParamOldPassword = oldPassword
        changeVaultPasswordParamNewPassword = newPassword
        if let e = changeVaultPasswordError { throw e }
        completion(changeVaultPasswordResult)
    }
}

