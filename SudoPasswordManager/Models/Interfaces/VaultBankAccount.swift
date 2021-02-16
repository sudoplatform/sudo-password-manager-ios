//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents the details for a bank account.
public class VaultBankAccount: VaultItem {

    /// Name of this item.
    public var name: String

    /// Space to store notes about the service.
    public var notes: VaultItemNote?

    /// Account Type of this item.
    public var accountType: String?

    /// Name of the bank for this item.
    public var bankName: String?

    /// Branch Address of this item.
    public var branchAddress: String?

    /// Branch Phone Number of this item.
    public var branchPhone: String?

    /// IBAN of this item.
    public var ibanNumber: String?

    /// Routing Number or ABA/ABN Number of this item.
    public var routingNumber: String?

    /// Swift Code of this item.
    public var swiftCode: String?

    /// Account Number of this item.
    public var accountNumber: VaultItemValue?

    /// Account Pin of this item.
    public var accountPin: VaultItemValue?

    public init(id: String,
         createdAt: Date,
         updatedAt: Date,
         name: String,
         notes: VaultItemNote?,
         accountType: String?,
         bankName: String?,
         branchAddress: String?,
         branchPhone: String?,
         ibanNumber: String?,
         routingNumber: String?,
         swiftCode: String?,
         accountNumber: VaultItemValue?,
         accountPin: VaultItemValue?) {
        self.name = name
        self.notes = notes
        self.accountType = accountType
        self.bankName = bankName
        self.branchAddress = branchAddress
        self.branchPhone = branchPhone
        self.ibanNumber = ibanNumber
        self.routingNumber = routingNumber
        self.swiftCode = swiftCode
        self.accountNumber = accountNumber
        self.accountPin = accountPin
        super.init(id: id, createdAt: createdAt, updatedAt: updatedAt)
    }

    public convenience init(name: String,
                            notes: VaultItemNote?,
                            accountType: String?,
                            bankName: String?,
                            branchAddress: String?,
                            branchPhone: String?,
                            ibanNumber: String?,
                            routingNumber: String?,
                            swiftCode: String?,
                            accountNumber: VaultItemValue?,
                            accountPin: VaultItemValue?) {
        let id = UUID().uuidString
        let now = Date()
        self.init(id: id,
                  createdAt: now,
                  updatedAt: now,
                  name: name,
                  notes: notes,
                  accountType: accountType,
                  bankName: bankName,
                  branchAddress: branchAddress,
                  branchPhone: branchPhone,
                  ibanNumber: ibanNumber,
                  routingNumber: routingNumber,
                  swiftCode: swiftCode,
                  accountNumber: accountNumber,
                  accountPin: accountPin)
    }
}
