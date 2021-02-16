//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoPasswordManager

class VaultItemTests: XCTestCase {

    func testEntitlement() {
        let name = Entitlement.Name.maxVaultPerSudo
        let e = Entitlement(name: name, limit: 0)
        XCTAssertEqual(e.limit, 0)
        XCTAssertEqual(e.name, name)

        let state = EntitlementState(name: name, sudoId: "id", limit: 0, value: 0)
        XCTAssertEqual(state.name, name)
        XCTAssertEqual(state.sudoId, "id")
    }

    func testVault() {
        let owner = VaultOwner(id: "id", issuer: "issuer")
        XCTAssertEqual(owner.id, "id")
        XCTAssertEqual(owner.issuer, "issuer")

        let vault = Vault(id: "id", owner: "owner", owners: [], createdAt: Date(), updatedAt: Date())
        XCTAssertEqual(vault.id, "id")
        XCTAssertEqual(vault.owner, "owner")
    }

    func testVaultItemsAndLogin() {
        let now = Date()
        let item = VaultItem(id: "id", createdAt: now, updatedAt: now)
        XCTAssertEqual(item.id, "id")
        XCTAssertEqual(item.createdAt, now)
        XCTAssertEqual(item.updatedAt, now)

        let note = VaultItemNote(value: "note")
        XCTAssertEqual(try? note.getValue(), "note")

        let password = VaultItemPassword(value: "password")
        XCTAssertEqual(try? password.getValue(), "password")

        let login = VaultLogin(id: "id", createdAt: now, updatedAt: now, user: "user", url: "url", name: "name", notes: note, password: password, previousPasswords: [password])
        XCTAssertEqual(login.id, "id")
        XCTAssertEqual(login.createdAt, now)
        XCTAssertEqual(login.updatedAt, now)
        XCTAssertEqual(login.user, "user")
        XCTAssertEqual(login.url, "url")
        XCTAssertEqual(login.name, "name")
        XCTAssertEqual(try? login.notes?.getValue(), "note")
        XCTAssertEqual(try? login.password?.getValue(), "password")
    }

    func testBankAccount() {
        let now = Date()
        let note = VaultItemNote(value: "note")
        let accountNumber = VaultItemValue(value: "accountNumber")
        let pin = VaultItemValue(value: "pin")
        let account = VaultBankAccount(id: "id", createdAt: now, updatedAt: now, name: "name", notes: note, accountType: "type", bankName: "bankName", branchAddress: "branchAddress", branchPhone: "branchPhone", ibanNumber: "ibanNumber", routingNumber: "routingNumber", swiftCode: "swiftCode", accountNumber: accountNumber, accountPin: pin)

        XCTAssertEqual(account.id, "id")
        XCTAssertEqual(account.createdAt, now)
        XCTAssertEqual(account.updatedAt, now)
        XCTAssertEqual(account.name, "name")
        XCTAssertEqual(try? account.notes?.getValue(), "note")
        XCTAssertEqual(account.accountType, "type")
        XCTAssertEqual(account.bankName, "bankName")
        XCTAssertEqual(account.branchAddress, "branchAddress")
        XCTAssertEqual(account.branchPhone, "branchPhone")
        XCTAssertEqual(account.ibanNumber, "ibanNumber")
        XCTAssertEqual(account.routingNumber, "routingNumber")
        XCTAssertEqual(account.swiftCode, "swiftCode")
        XCTAssertEqual(try? account.accountNumber?.getValue(), "accountNumber")
        XCTAssertEqual(try? account.accountPin?.getValue(), "pin")
    }

    func testCreditCard() {
        let now = Date()
        let note = VaultItemNote(value: "note")
        let number = VaultItemValue(value: "cardNumber")
        let sc = VaultItemValue(value: "securityCode")
        let card = VaultCreditCard(id: "id", createdAt: now, updatedAt: now, name: "name", notes: note, cardType: "type", cardName: "cardName", cardExpiration: now, cardNumber: number, cardSecurityCode: sc)

        XCTAssertEqual(card.id, "id")
        XCTAssertEqual(card.createdAt, now)
        XCTAssertEqual(card.updatedAt, now)
        XCTAssertEqual(card.name, "name")
        XCTAssertEqual(try? card.notes?.getValue(), "note")
        XCTAssertEqual(card.cardType, "type")
        XCTAssertEqual(card.cardName, "cardName")
        XCTAssertEqual(card.cardExpiration, now)
        XCTAssertEqual(try? card.cardNumber?.getValue(), "cardNumber")
        XCTAssertEqual(try? card.cardSecurityCode?.getValue(), "securityCode")
    }
}
