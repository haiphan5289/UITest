//
//  UIBarButtonItem+View.swift
//  GooDic
//
//  Created by ttvu on 10/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    var view: UIView? {
        self.value(forKey: "view") as? UIView
    }
}
