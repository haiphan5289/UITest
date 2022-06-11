//
//  NSLayoutConstraint+Extension.swift
//  GooDic
//
//  Created by ttvu on 12/9/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    
    @discardableResult
    func active(with priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        self.isActive = true
        
        return self
    }
    
    @discardableResult
    func setPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        
        return self
    }
}
