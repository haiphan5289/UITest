//
//  UITableViewCell+CheckMarkImageView.swift
//  GooDic
//
//  Created by ttvu on 10/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UITableViewCell {
    func setCheckMarkImageView(image: UIImage?) {
        guard let editControlClass = NSClassFromString("UITableViewCellEditControl") else { return }
        
        self.subviews.forEach { (view) in
            if view.isMember(of: editControlClass) {
                let imageView = view.value(forKey: "_imageView") as? UIImageView
                imageView?.image = image
            }
        }
    }
}
