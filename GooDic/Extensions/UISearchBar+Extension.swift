//
//  UISearchBar+Extension.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UISearchBar {
    
    func getTextField() -> UITextField? {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            // Fallback on earlier versions
            guard let contentView = subviews.first else { return nil }
            let textField = contentView.subviews.first(where: { $0 is UITextField }) as? UITextField
            return textField
        }
    }
}
