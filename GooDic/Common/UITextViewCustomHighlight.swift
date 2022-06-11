//
//  UITextViewCustomHighlight.swift
//  TextView
//
//  Created by ttvu on 6/25/20.
//  Copyright © 2020 vutt. All rights reserved.
//

import UIKit

/// Some font has a leading (bottom gap), It makes the highlight area be shifted down.
/// _______.
/// | TEXT   |
/// |______|
/// This class will calculate and update the highlight's frame to fix to the content.
class UITextViewCustomHighlight: UITextView {
    
    override var font: UIFont? {
        didSet {
            /// update `leadingFont` after the font's changed
            if let font = font {
                leadingFont = font.leading
            } else {
                leadingFont = 0
            }
        }
    }
    
    var leadingFont: CGFloat = 0
    
    lazy var seek: CGFloat = {
        let documentHeightLine = self.caretRect(for: self.beginningOfDocument).height
        let fontHeight = font?.lineHeight ?? documentHeightLine
        let seek = (documentHeightLine - fontHeight) * 0.5
        return seek
    }()
    
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        let list = super.selectionRects(for: range).map { (tsr) -> UITextSelectionRect in
            let rect = CGRect(origin: CGPoint(x: tsr.rect.origin.x, y: tsr.rect.origin.y - seek),
                              size: tsr.rect.size)
            let newObj = MyTextSelectionRect(rect: rect,
                                             writingDirection: tsr.writingDirection,
                                             containsStart: tsr.containsStart,
                                             containsEnd: tsr.containsEnd,
                                             isVertical: tsr.isVertical)
            return newObj
        }

        return list
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        var newRect = super.caretRect(for: position)
        let fontHeight = font?.lineHeight ?? newRect.height
        let seek = (newRect.height - fontHeight) * 0.5
        newRect.origin = CGPoint(x: newRect.origin.x, y: newRect.origin.y - seek)
        return newRect
    }
    
    /// Return the first rectangle that encloses a range of text in a document
    /// it's also used to draw the highlight
    override func firstRect(for range: UITextRange) -> CGRect {
        var newRect = super.firstRect(for: range)
        newRect.origin = CGPoint(x: newRect.origin.x, y: newRect.origin.y - leadingFont)
        return newRect
    }
}

public final class MyTextSelectionRect: UITextSelectionRect {
    public override var rect: CGRect { _rect }
    public override var writingDirection: NSWritingDirection { _writingDirection }
    public override var containsStart: Bool { _containsStart }
    public override var containsEnd: Bool { _containsEnd }
    public override var isVertical: Bool { _isVertical }

    private let _rect: CGRect
    private let _writingDirection: NSWritingDirection
    private let _containsStart: Bool
    private let _containsEnd: Bool
    private let _isVertical: Bool

    public init(
        rect: CGRect,
        writingDirection: NSWritingDirection,
        containsStart: Bool,
        containsEnd: Bool,
        isVertical: Bool
    ) {
        _rect = rect
        _writingDirection = writingDirection
        _containsStart = containsStart
        _containsEnd = containsEnd
        _isVertical = isVertical
    }
}
