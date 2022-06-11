//
//  BorderView.swift
//  GooDic
//
//  Created by ttvu on 11/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

@IBDesignable
class BorderView: UIView, CapsuleProtocol {
    @IBInspectable var cornerRadius: CGFloat = 6.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = self.borderWidth
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        makeCapsule()
    }
}
