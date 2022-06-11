//
//  MenuControllerSupportingView.swift
//  GooDic
//
//  Created by ttvu on 6/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// a view which the menu controller can be displayed
class MenuControllerSupportingView: UIView {
    
    /// be required to present menu controller
    override var canBecomeFirstResponder: Bool { true }
    
    /// don't show any default menu items
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
