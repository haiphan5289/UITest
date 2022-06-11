//
//  UITableViewCell+Action.swift
//  GooDic
//
//  Created by ttvu on 5/28/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UITableViewCell {
    var cellActionButtonLabel: UILabel? {
        superview?.subviews
            .filter { String(describing: $0).range(of: "UISwipeActionPullView") != nil }
            .flatMap { $0.subviews }
            .filter { String(describing: $0).range(of: "UISwipeActionStandardButton") != nil }
            .flatMap { $0.subviews }
            .compactMap { $0 as? UILabel }.first
    }
}
