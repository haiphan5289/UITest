//
//  NSRange+Extension.swift
//  GooDic
//
//  Created by ttvu on 5/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension NSRange {
    func toTextRange(textInput:UITextInput) -> UITextRange? {
        if let rangeStart = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length) {
            return textInput.textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
}
