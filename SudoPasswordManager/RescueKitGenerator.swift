//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PDFKit

class RescueKitGenerator: NSObject, PDFDocumentDelegate {
    /// Generates a PDF containing the secret code.
    /// - Parameters:
    ///   - code: The secret code belonging to the user.
    /// - Returns: A PDFDocument if successful, or nil if unable to find the PDF file.
    public func generatePDF(with code: String) -> PDFDocument? {
        if let document = loadDocument() {
            document.delegate = self
            if let page = document.page(at: 0), let codePage = page as? RescueKitSecretCodePage {
                codePage.set(code)
            }
            return document
        }
        return nil
    }
    
    // Implementation from the PDFDocumentDelegate
    func classForPage() -> AnyClass {
        return RescueKitSecretCodePage.self
    }
    
    // Loads the document from the Bundle
    private func loadDocument() -> PDFDocument? {
        let bundle = Bundle(for: self.classForCoder)
        if let bundleUrl = bundle.url(forResource: "RescueKit", withExtension: "pdf") {
                return PDFDocument(url: bundleUrl)
        }
        return nil
    }
}
