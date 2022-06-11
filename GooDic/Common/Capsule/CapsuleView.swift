//
//  CapsuleView.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

protocol CapsuleProtocol: UIView {
    var cornerRadius: CGFloat { get }
    func makeCapsule()
}

extension CapsuleProtocol {
    var cornerRadius: CGFloat {
        self.frame.height / 2
    }
    
    func makeCapsule() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = cornerRadius
    }
}

@IBDesignable
class CapsuleView: UIView, CapsuleProtocol {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        makeCapsule()
    }
}
