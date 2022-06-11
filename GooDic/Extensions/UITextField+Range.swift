//
//  UITextField+Range.swift
//  GooDic
//
//  Created by ttvu on 8/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UITextField {
    
    var selectedRangeStringIndex: Range<String.Index>? {
        
        guard let text = text else { return nil }
        
        var selectedRange: Range<String.Index>? = nil
        if let textRange = self.selectedTextRange {
            let begin = self.beginningOfDocument
            let location = self.offset(from: begin, to: textRange.start)
            let length = self.offset(from: textRange.start, to: textRange.end)
            
            if length == 0 {
                return nil
            }
            
            let range = NSRange(location: location, length: length)
            selectedRange = Range<String.Index>(range, in: text)
        }
        
        return selectedRange
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
}

extension UILabel {
    
    func getLinesArrayOfString() -> [String]? {
            
            /// An empty string's array
            var linesArray = [String]()
            
            guard let text = self.text, let font = self.font else {return linesArray}
            
            let rect = self.frame
            
            let myFont = CTFontCreateWithFontDescriptor(font.fontDescriptor, 0, nil)
            let attStr = NSMutableAttributedString(string: text)
            attStr.addAttribute(kCTFontAttributeName as NSAttributedString.Key, value: myFont, range: NSRange(location: 0, length: attStr.length))
            
            let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
            let path: CGMutablePath = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: rect.size.width, height: 100000), transform: .identity)
            
            let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
            guard let lines = CTFrameGetLines(frame) as? [Any] else {return linesArray}
            
            for line in lines {
                let lineRef = line as! CTLine
                let lineRange: CFRange = CTLineGetStringRange(lineRef)
                let range = NSRange(location: lineRange.location, length: lineRange.length)
                let lineString: String = (text as NSString).substring(with: range)
                linesArray.append(lineString)
            }
            return linesArray
     }
    
    func setLineHeight(
        lineHeight: CGFloat,
        shouldCenter: Bool = false,
        firstLineHeadIndent: CGFloat = 0,
        headIndent: CGFloat = 0,
        paragraphSpacing: CGFloat = 6
    ) {
        let text = self.text
        if let text = text {
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            
            style.lineSpacing = lineHeight
            style.paragraphSpacing = paragraphSpacing
            style.firstLineHeadIndent = firstLineHeadIndent
            style.headIndent = headIndent
            style.lineBreakMode = .byTruncatingTail
            if shouldCenter {
                style.alignment = .center
            }
            attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSAttributedString.Key.kern, value: 0, range: NSMakeRange(0, attributeString.length))
            self.attributedText = attributeString
        }
    }

    var maxNumberOfLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: UIFont.hiraginoSansW4(size: 14)], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
    
    var lines: [String]? {

            guard let text = text, let font = font else { return nil }

            let attStr = NSMutableAttributedString(string: text)
            attStr.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: attStr.length))

            let frameSetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
            let path = CGMutablePath()

            // size needs to be adjusted, because frame might change because of intelligent word wrapping of iOS
            let size = sizeThatFits(CGSize(width: self.frame.width, height: .greatestFiniteMagnitude))
            path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height), transform: .identity)

            let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attStr.length), path, nil)
            guard let lines = CTFrameGetLines(frame) as? [Any] else { return nil }

            var linesArray: [String] = []

            for line in lines {
                let lineRef = line as! CTLine
                let lineRange = CTLineGetStringRange(lineRef)
                let range = NSRange(location: lineRange.location, length: lineRange.length)
                let lineString = (text as NSString).substring(with: range)
                linesArray.append(lineString)
            }
            return linesArray
        }
}
