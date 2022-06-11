//
//  UIBarButtonItem.swift
//  GooDic
//
//  Created by ttvu on 6/1/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// helping to create BarButtonItem with the same style
extension UIBarButtonItem {
    class func createDismissButton() -> UIBarButtonItem {
        let leftBarButtonItem = UIBarButtonItem(image: Asset.icDismiss.image, style: .done, target: nil, action: nil)
        return leftBarButtonItem
    }
}
