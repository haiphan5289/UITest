//
//  UITextView+Range.swift
//  GooDic
//
//  Created by ttvu on 8/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UITextView {
    
    var selectedRangeStringIndex: Range<String.Index>? {
        guard let text = text else { return nil }
        
        var range: Range<String.Index>? = nil
        
        if selectedRange.length > 0 {
            range = Range<String.Index>(selectedRange, in: text)
        }
        
        return range
    }
    
    var markedTextRangeStringIndex: Range<String.Index>? {
        guard let text = text else { return nil }
        
        var markedRange: Range<String.Index>? = nil
        if let textRange = self.markedTextRange {
            let begin = self.beginningOfDocument
            let location = self.offset(from: begin, to: textRange.start)
            let length = self.offset(from: textRange.start, to: textRange.end)
            
            if length == 0 {
                return nil
            }
            
            let range = NSRange(location: location, length: length)
            markedRange = Range<String.Index>(range, in: text)
        }
        
        return markedRange
    }
    
    func getTextFromRange(range: NSRange?) -> String? {
        if let range = range, let text = self.text {
            let startIndex = text.index(text.startIndex, offsetBy: range.location)
            let endIndex = text.index(text.startIndex, offsetBy: range.location + range.length - 1)
            let replaceText = String(text[startIndex...endIndex])
            return replaceText
        }
        return nil
    }
    
    func getTextRangeFromRange(range: NSRange) -> UITextRange? {
        if  let fromTextPosition = self.position(from: self.beginningOfDocument, offset: range.location),
            let toTextPosition = self.position(from: fromTextPosition, offset: range.length),
            let textRange = self.textRange(from: fromTextPosition, to: toTextPosition) {
            return textRange
        }
        return nil
    }
}
