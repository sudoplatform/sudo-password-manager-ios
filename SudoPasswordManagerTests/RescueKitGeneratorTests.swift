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

    func testGeneratorWithDefaultTemplate() {
        guard let generator = RescueKitGenerator() else {
            XCTFail()
            return
        }
        self.testDocument(generator: generator, generates: self.secretCode)
    }

    func testTemplateGenerator() {
        let bundle = Bundle(for: RescueKitGenerator.classForCoder())
        guard let bundleUrl = bundle.url(forResource: "RescueKit", withExtension: "pdf"), let template = PDFDocument(url: bundleUrl) else {
            XCTFail()
            return
        }

        guard let generator = RescueKitGenerator(template: template) else {
            XCTFail()
            return
        }

        self.testDocument(generator: generator, generates: self.secretCode)
    }

    func testDocument(generator: RescueKitGenerator, generates secretCode: String) {
        let document = generator.generatePDF(with: secretCode)
        // In order to find the secret code as a string, the document needs to be made into data then back to a PDFDocument
        let data = document.dataRepresentation()
        if let pdf = PDFDocument(data: data!) {
            let results = pdf.findString(secretCode)
            XCTAssert(results.count == 1)
        }
    }
}
