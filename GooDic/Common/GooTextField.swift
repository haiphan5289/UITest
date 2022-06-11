//
//  GooTextField.swift
//  GooDic
//
//  Created by ttvu on 6/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// a TextField used in the preview screen (the reference screen)
class GooTextField: UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        /// disable `define`, `addShortcut` , `share`, `paste` menu item
        if action.description == "_define:" ||
            action.description == "_addShortcut:" ||
            action.description == "_share:" ||
            action.description == "paste:" ||
            action.description == "_translate:" {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
}

/// a TextField used in creation screen
class GooTextFieldWithPasteAction: UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        /// disable `define`, `addShortcut` , and `share` menu item
        if action.description == "_define:" ||
            action.description == "_addShortcut:" ||
            action.description == "_share:" ||
            action.description == "_translate:"  {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    // MARK: Tracking
    override func select(_ sender: Any?) {
        super.select(sender)
        
        trackTapOnMenuButton()
    }
    
    override func selectAll(_ sender: Any?) {
        super.selectAll(sender)
        
        trackTapOnMenuButton()
    }
    
    override func paste(_ sender: Any?) {
        super.paste(sender)
        
        trackTapOnMenuButton()
    }
    
    override func copy(_ sender: Any?) {
        super.copy(sender)
        
        trackTapOnMenuButton()
    }
    
    override func cut(_ sender: Any?) {
        super.cut(sender)
        
        trackTapOnMenuButton()
    }
    
    func trackTapOnMenuButton() {
        GATracking.tap(.tapHandle)
    }
    
    // MARK: Japanese Input Mode
    /// get Japanese Input Mode if it is enabling on the user's device
    var jpTextInputMode: UITextInputMode? = {
        let lang = "ja-JP"
        for mode in UITextInputMode.activeInputModes {
            if let langText = mode.primaryLanguage, langText.localizedStandardContains(lang) {
                return mode
            }
        }
        return nil
    }()
    
    /// override input mode to get japanese input mode first. Using the default instead if it's not availabe.
    override var textInputMode: UITextInputMode? {
        return jpTextInputMode ?? super.textInputMode
    }
}

extension UITextField {
    /// get the name of input mode
    /// Because the `textInputMode` function 's overrided to get Japanese Input Mode, it alway returns 'ja-JP' if Japanese Input Mode is available.
    /// So we need this func to get the name from super.
    var currentInputModeString: String? {
        super.textInputMode?.primaryLanguage
    }
}
