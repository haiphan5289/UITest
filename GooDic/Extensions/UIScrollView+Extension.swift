//
//  UIScrollView+Extension.swift
//  GooDic
//
//  Created by ttvu on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIScrollView {
    func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
        return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height && self.contentSize.height > self.frame.size.height
    }
}

