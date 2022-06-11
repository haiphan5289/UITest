//
//  GooTextView.swift
//  GooDic
//
//  Created by ttvu on 6/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// a text view used in the preview screen (the reference screen)
class GooTextView: PlaceholderTextView {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        /// disable `define`, `addShortcut` , `share`, `paste` menu item
        if action.description == "_define:" ||
            action.description == "_addShortcut:" ||
            action.description == "_share:" ||
            action.description == "paste:" ||
            action.description == "_translate:" {
            return false
        }
        
        let result = super.canPerformAction(action, withSender: sender)
        print("\(action.description) \(result)")
        return result
    }
    
    override func trackTapOnMenuButton() {
        // Do nothing. I don't want to send any tracking events
    }
}
