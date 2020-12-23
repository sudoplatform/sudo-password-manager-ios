//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Wrapper for errors that are returned from the password manager.
public struct PasswordManagerError: Error {

    /// Types of the errors returned by the password manager.
    public enum ErrorType: String, CaseIterable {
        ///The version of the vault that's being updated or deleted does not match the version stored in the backed. It is likely that another client updated the vault first so the caller should reconcile the changes before attempting to update or delete the vault.
        case versionMismatch

        /// The user is not authorized to perform the requested operation. This maybe due to specifying the wrong key deriving key or password.
        case notAuthorized

        ///The vault data retrieved is invalid. This indicates the vault is corrupt or is encrypted using a key that's not known to the client.
        case invalidVault

        /// The vault is locked and must be unlocked before this action will succeed.
        case vaultLocked

        /// The password is invalid or no secret code exists locally.
        case invalidPasswordOrMissingSecretCode

        /// The format of the input was invalid.
        case invalidFormat

        /// There was a problem using Security framework, e.g. unable to access the keychain or generate secure keys.
        case security

        /// An unknown error occured.
        case unknown

        /// An error was returned by the Sudo Secure Vault service.
        case secureVaultService

        /// An internal error occured. This is most likely due to an internal framework, e.g unable to generate encryption keys.
        case `internal`

        /// Converts the error type into an error
        public func asError() -> PasswordManagerError {
            return PasswordManagerError(type: self)
        }
    }

    /// The type of the error
    public let type: ErrorType

    /// A reference to the underlying error which caused this, if it exists.
    public let underlyingError: Error?

    /// An optional place to put additional error related information.
    public var userInfo: [String: Any]?

    public struct UserInfoKey {
        static let debugDescription: String = "DebugDescription"
    }

    public init(type: ErrorType, underlyingError: Error? = nil, userInfo: [String: Any]? = nil) {

        // Check the underlying type first to avoid recursive errors.
        if let underlyingError = (underlyingError as? PasswordManagerError), underlyingError.type == type {
            self.type = underlyingError.type
            self.underlyingError = underlyingError.underlyingError
            self.userInfo = userInfo ?? underlyingError.userInfo
        } else {
            self.type = type
            self.underlyingError = underlyingError
            self.userInfo = userInfo
        }
    }
}

/// To better support translating errors into text.
extension PasswordManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self.type {
        case .invalidPasswordOrMissingSecretCode:
            return "The password is invalid or no secret code exists locally"
        case .invalidVault:
            return "The vault data retrieved is invalid. This indicates the vault is corrupt or is encrypted using a key that's not known to the client"
        case .notAuthorized:
            return "The user is not authorized to perform the requested operation. This maybe due to specifying the wrong key deriving key or password"
        case .unknown:
            return "An unknown error occurred"
        case .vaultLocked:
            return "The vault is locked and must be unlocked to proceed"
        case .versionMismatch:
            return "The version of the vault that's being updated or deleted does not match the version stored in the backed. It is likely that another client updated the vault first so the caller should reconcile the changes before attempting to update or delete the vault"
        case .invalidFormat:
            return "The format of the input was invalid"
        case .security:
            return "There was a problem using the system Security framework"
        case .internal:
            return "An internal error occured. This is most likely due to an internal framework, e.g unable to generate encryption keys."
        case .secureVaultService:
            return "The Sudo Secure Vault service returned an error during an operation."
        }
    }
}

/// Allows you to easily create errors as if this were an enum
/// e.g. let error = PasswordManagerClientError.versionMismatch
///
/// var error: PasswordManagerClientError
/// error = .versionMismatch
///
extension PasswordManagerError {
    static var versionMismatch = PasswordManagerError(type: .versionMismatch)
    static var notAuthorized = PasswordManagerError(type: .notAuthorized)
    static var invalidFormat = PasswordManagerError(type: .invalidFormat)
    static var invalidVault = PasswordManagerError(type: .invalidVault)
    static var vaultLocked = PasswordManagerError(type: .vaultLocked)
    static var invalidPasswordOrMissingSecretCode = PasswordManagerError(type: .invalidPasswordOrMissingSecretCode)
    static var security = PasswordManagerError(type: .security)
    static var unknown = PasswordManagerError(type: .unknown)
}
