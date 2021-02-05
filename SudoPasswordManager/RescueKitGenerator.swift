//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PDFKit

class RescueKitGenerator: NSObject, PDFDocumentDelegate {

    let template: PDFDocument

    /// Creates a rescue kit generator
    /// - Parameter template: The optional template pdf to use. If nil the default from the bundle will be used.
    init?(template: PDFDocument? = nil) {
        if let template = template {
            self.template = template
        }
        else {
            let bundle = Bundle(for: Self.classForCoder())
            guard let bundleUrl = bundle.url(forResource: "RescueKit", withExtension: "pdf"), let template = PDFDocument(url: bundleUrl) else {
                return nil
            }
            self.template = template
        }
    }

    /// Generates a PDF containing the secret code.
    /// - Parameters:
    ///   - code: The secret code belonging to the user.
    /// - Returns: A PDFDocument with the secret code added.
    func generatePDF(with code: String) -> PDFDocument {
        template.delegate = self
        if let page = template.page(at: 0), let codePage = page as? RescueKitSecretCodePage {
            codePage.set(code)
        }
        return template
    }
    
    // Implementation from the PDFDocumentDelegate
    func classForPage() -> AnyClass {
        return RescueKitSecretCodePage.self
    }
}
