//
//  UITextView+ContentInsets.swift
//  GooDic
//
//  Created by ttvu on 7/28/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UITextView {
    
    func scrollToBottom() {
        self.layoutManager.ensureLayout(for: self.textContainer)
        
        let height = self.visibleSize.height - contentInset.bottom - textContainerInset.bottom
        let offsetY = self.contentSize.height - height - 1 // In some cases, the textView can be scrolled back to the top if you scrolls it to the bottom exactly. That's why the value minus by 1
        
        if offsetY > 0 {
            let offset = CGPoint(x: 0, y: offsetY)
            self.setContentOffset(offset, animated: true)
        }
    }
    
    /// Scrolls to visible range, eventually considering insets
    /// - Parameters:
    ///   - range: range of text
    ///   - considerInsets: to use or not to use insets
    func scrollRangeToVisible(_ range: NSRange, consideringInsets considerInsets: Bool) {
        if considerInsets {
            if let start = self.position(from: self.beginningOfDocument, offset: range.location),
                let end = self.position(from: start, offset: range.length),
                let textRange = textRange(from: start, to: end) {
                
                // force textView's textContainer to ensure the layout of textView immediately,
                // it'll give you right rect, even though the textview allows a non-contiguous layout
                self.layoutManager.ensureLayout(for: self.textContainer)
                
                var rect = firstRect(for: textRange)
                
                let list = selectionRects(for: textRange)
                list.forEach { (textRect) in
                    rect = rect.union(textRect.rect)
                }
                
                scrollRectToVisible(rect, animated: true, consideringInsets: true)
            }
        } else {
            scrollRangeToVisible(range)
        }
    }
    
    /// Scrolls to visible rect, eventually considering insets
    /// - Parameters:
    ///   - rect: rect to visible
    ///   - animated: to play or not to play the animation
    ///   - considerInsets: to use or not to use insets
    func scrollRectToVisible(_ rect: CGRect, animated: Bool, consideringInsets considerInsets: Bool) {
        if considerInsets {
            // Gets bounds and calculates visible rect
            let bounds = self.bounds
            let visibleRect = visibleRectConsideringInsets(true)
            
            // Do not scroll if rect is on screen
            if visibleRect.contains(rect) == false {
                var contentOffset = self.contentOffset
                // Calculates new contentOffset
                if rect.origin.y < visibleRect.origin.y {
                    // rect precedes bounds, scroll up
                    contentOffset.y = rect.origin.y - contentInset.top - textContainerInset.top
                    contentOffset.y = contentOffset.y < 0 ? 0 : contentOffset.y
                } else {
                    // rect follows bounds, scroll down
                    contentOffset.y = rect.origin.y + rect.size.height + contentInset.bottom - bounds.size.height + textContainerInset.bottom
                }
                
                setContentOffset(contentOffset, animated: animated)
            }
        } else {
            scrollRectToVisible(rect, animated: animated)
        }
    }
    
    /// Returns visible rect, eventually considering insets
    func visibleRectConsideringInsets(_ considerInsets: Bool) -> CGRect {
        var bounds = self.bounds
        
        if considerInsets {
            bounds.origin.x += contentInset.left
            bounds.origin.y += contentInset.top + textContainerInset.top
            bounds.size.width -= contentInset.right + contentInset.right
            bounds.size.height -= contentInset.top + contentInset.bottom + textContainerInset.top + textContainerInset.bottom
        }
        
        return bounds
    }
}
