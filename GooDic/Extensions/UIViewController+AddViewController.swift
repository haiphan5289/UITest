//
//  UIViewController+AddViewController.swift
//  GooDic
//
//  Created by ttvu on 1/4/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

extension UIViewController {
    func quickRemove() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    func quickAdd(vc: UIViewController) -> UIView {
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        return vc.view
    }
}
