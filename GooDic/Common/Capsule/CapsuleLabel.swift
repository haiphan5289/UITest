//
//  CapsuleLabel.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

@IBDesignable
class CapsuleLabel: UILabel, CapsuleProtocol {
    
    @IBInspectable var topPadding: CGFloat = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var leftPadding: CGFloat = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var rightPadding: CGFloat = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var bottomPadding: CGFloat = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var gap: CGFloat {
        get {
            self.bounds.height / 2
        }
    }
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topPadding, left: leftPadding, bottom: bottomPadding, right: rightPadding)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        makeCapsule()
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftPadding + rightPadding, height: size.height + topPadding + bottomPadding)
    }
}
