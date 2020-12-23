//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import PDFKit
@testable import SudoPasswordManager

class RescueKitGeneratorTests: XCTestCase {

    var generator: RescueKitGenerator!
    let secretCode: String = "ABCDEF-GHIJK-LMNOP-QRSTU-VWXYZ-123456"
    
    override func setUpWithError() throws {
        self.generator = RescueKitGenerator()
        
        XCTAssertNotNil(generator)
    }
    func testGeneratorReturnsBlankPDF() {
        let data = generator.generatePDF(with: "")
        XCTAssertNotNil(data)
    }
    
    func testGeneratorReturnsPDFWithPassword() {
        let document = generator.generatePDF(with: secretCode)
        XCTAssertNotNil(document)
        // In order to find the secret code as a string, the document needs to be made into data then back to a PDFDocument
        let data = document?.dataRepresentation()
        if let pdf = PDFDocument(data: data!) {
            let results = pdf.findString(secretCode)
            XCTAssert(results.count == 1)
        }
    }

}
