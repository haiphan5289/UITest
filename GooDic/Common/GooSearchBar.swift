//
//  GooSearchBar.swift
//  GooDic
//
//  Created by ttvu on 8/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// a search bar which can present a Japanese Input Mode if needed
class GooSearchBar: UISearchBar {
    
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

