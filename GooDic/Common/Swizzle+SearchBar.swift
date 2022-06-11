//
//  Swizzle+SearchBar.swift
//  GooDic
//
//  Created by ttvu on 3/16/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

extension UITextField {
    
    struct Constants {
        static let seek: CGFloat = 6
    }
    
    @objc static func swizzle() -> Void {
        if let vc = NSClassFromString("UISearchBarTextField") {
            Swizzle(vc.self) {
                #selector(drawText(in:)) <-> #selector(_drawText(in:))
                #selector(textRect(forBounds:)) <-> #selector(_textRect(forBounds:))
                #selector(editingRect(forBounds:)) <-> #selector(_editingRect(forBounds:))
//                #selector(drawText(in:)) <-> #selector(_drawText(in:))
//                #selector(caretRect(for:)) <-> #selector(_caretRect(for:))
//                #selector(firstRect(for:)) <-> #selector(_firstRect(for:))
//                #selector(selectionRects(for:)) <-> #selector(_selectionRects(for:))
            }
        }
    }
    
    @objc private func _selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        let list = _selectionRects(for: range).map { (tsr) -> UITextSelectionRect in
            let rect = tsr.rect.insetBy(dx: 0, dy: -Constants.seek)
            let newObj = MyTextSelectionRect(rect: rect,
                                             writingDirection: tsr.writingDirection,
                                             containsStart: tsr.containsStart,
                                             containsEnd: tsr.containsEnd,
                                             isVertical: tsr.isVertical)
            return newObj
        }

        return list
    }
    
//    @objc private func _caretRect(for position: UITextPosition) -> CGRect {
//        var newRect = _caretRect(for: position)
//        newRect = newRect.insetBy(dx: 0, dy: -Constants.seek)
//        return newRect
//    }
//
//    @objc private func _firstRect(for range: UITextRange) -> CGRect {
//        var newRect = _firstRect(for: range)
//        newRect = newRect.insetBy(dx: 0, dy: -Constants.seek)
//        return newRect
//    }
    
    func textInsets() -> UIEdgeInsets {
        UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    @objc private func _textRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = self._textRect(forBounds: bounds)
        return newBounds.inset(by: textInsets())
    }

    @objc private func _drawText(in rect: CGRect) {
        let newRect = rect.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 400))
        self._drawText(in: newRect)
    }

    
    @objc private func _editingRect(forBounds bounds: CGRect) -> CGRect {
        let newRect = self._editingRect(forBounds: bounds)
        return newRect.inset(by: textInsets())
    }

    
//    @objc private func _drawText(in rect: CGRect) {
//        let textInsets = UIEdgeInsets(top: -5, left: 0, bottom: -5, right: 0)
//        _drawText(in: rect.inset(by: textInsets))
//    }
    
    
    
}
