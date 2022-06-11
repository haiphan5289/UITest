//
//  BaseNavigationController.swift
//  GooDic
//
//  Created by ttvu on 10/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    // Use for need add banner view above navigation bar, value is a height of banner
    var heightExtend: CGFloat = -1
    
    override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if heightExtend < 0 {
            return
        }
        // Only exucute it for ios 12
        var topPadding: CGFloat = 0
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            topPadding = window?.safeAreaInsets.top ?? 0
        }
        navigationBar.frame = CGRect(x: 0, y: topPadding + heightExtend, width: view.frame.width, height: navigationBar.frame.height)
    }
    
}
