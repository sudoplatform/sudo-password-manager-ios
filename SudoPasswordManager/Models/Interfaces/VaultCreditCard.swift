//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents the details for a credit card.
public class VaultCreditCard: VaultItem {

    /// Name of this item.
    public var name: String

    /// Space to store notes about the service.
    public var notes: VaultItemNote?

    /// Card Type of this item.
    public var cardType: String?

    /// Card holder's name of this item.
    public var cardName: String?

    /// Expiration Date of this item.
    public var cardExpiration: Date?

    /// Credit Card Number of this item.
    public var cardNumber: VaultItemValue?

    /// Credit Card Security Code of this item.
    public var cardSecurityCode: VaultItemValue?

    public init(id: String,
         createdAt: Date,
         updatedAt: Date,
         name: String,
         notes: VaultItemNote?,
         cardType: String?,
         cardName: String?,
         cardExpiration: Date?,
         cardNumber: VaultItemValue?,
         cardSecurityCode: VaultItemValue?) {
        self.name = name
        self.notes = notes
        self.cardType = cardType
        self.cardName = cardName
        self.cardExpiration = cardExpiration
        self.cardNumber = cardNumber
        self.cardSecurityCode = cardSecurityCode
        super.init(id: id, createdAt: createdAt, updatedAt: updatedAt)
    }

    public convenience init(name: String,
                            notes: VaultItemNote?,
                            cardType: String?,
                            cardName: String?,
                            cardExpiration: Date?,
                            cardNumber: VaultItemValue?,
                            cardSecurityCode: VaultItemValue?) {
        let id = UUID().uuidString
        let now = Date()
        self.init(id: id,
                  createdAt: now,
                  updatedAt: now,
                  name: name,
                  notes: notes,
                  cardType: cardType,
                  cardName: cardName,
                  cardExpiration: cardExpiration,
                  cardNumber: cardNumber,
                  cardSecurityCode: cardSecurityCode)
    }
}
