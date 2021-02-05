//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PDFKit

class RescueKitSecretCodePage: PDFPage {
    private static var code: NSString = ""
    
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        super.draw(with: box, to: context)
        
        UIGraphicsPushContext(context)
        context.saveGState()
        
        let pageBounds = self.bounds(for: box)
        context.translateBy(x: 0.0, y: pageBounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let string: NSString = RescueKitSecretCodePage.code
        let fontSize: CGFloat = 18
        let font = UIFont(name: "Courier-Bold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: font
        ]
        let stringSize = string.size(withAttributes: attributes)
        string.draw(at: CGPoint(x: (pageBounds.size.width - stringSize.width) / 2, y: (pageBounds.size.height - (pageBounds.size.height / 4.75))), withAttributes: attributes)
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
    
    func set(_ code: String) {
        RescueKitSecretCodePage.code = NSString(string: code)
    }
    
}
