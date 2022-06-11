//
//  ContainerViewController.swift
//  GooDic
//
//  Created by ttvu on 6/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// a view controller, using to embed the root view controller.
/// I used it to resolve cosmetics issues
class ContainerViewController: BaseViewController {
    
    var root: UIViewController
    var customOrientationMask: UIInterfaceOrientationMask?
    
    init(root: UIViewController) {
        self.root = root
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(root)
        self.view.addSubview(root.view)
        root.view.frame = view.bounds
        root.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.didMove(toParent: self)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return customOrientationMask ?? root.supportedInterfaceOrientations
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.view.layer.shadowColor = Asset.naviBarShadow.color.cgColor
        }
    }
}
