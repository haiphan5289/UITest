//
//  UITabBarItem+View.swift
//  GooDic
//
//  Created by ttvu on 10/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UITabBarItem {
    var view: UIView? {
        self.value(forKey: "view") as? UIView
    }
    
    var iconView: UIView? {
        if #available(iOS 13.0, *) {
            return view?.subviews.first?.subviews.first?.subviews.first(where: { $0 is UIImageView })
        } else {
            return view?.subviews.first(where: { $0 is UIImageView })
        }
    }
}

extension UITabBar {

    func getFrameForTabAt(index: Int) -> CGRect? {
        var frames = self.subviews.compactMap { return $0 is UIControl ? $0.frame : nil }
        frames.sort { $0.origin.x < $1.origin.x }
        return frames[safe: index]
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

}
