//
//  GooLayoutManager.swift
//  GooDic
//
//  Created by ttvu on 9/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class GooLayoutManager: NSLayoutManager {
    
    // draw background color to place it in vertical center of selected text
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        
        let font = self.textStorage?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        
        let currentContext = UIGraphicsGetCurrentContext()
        currentContext?.saveGState()
        currentContext?.setFillColor(color.cgColor)
        
        let lineHeight = self.lineFragmentRect(forGlyphAt: 0, effectiveRange: nil).size.height
        
        for i in 0..<rectCount {
            // re-calculate the rect
            var drawRect = rectArray[i]
            let fontHeight: CGFloat = font?.lineHeight ?? drawRect.size.height
            let seek = (lineHeight - fontHeight) * 0.5
            drawRect.origin.y = drawRect.origin.y - seek
            
            currentContext?.fill(drawRect)
        }
        
        currentContext?.restoreGState()
    }
}
