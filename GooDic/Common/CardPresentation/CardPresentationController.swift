//
//  CardPresentationController.swift
//  GooDic
//
//  Created by ttvu on 11/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class CardPresentationController: UIPresentationController {
    
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
    }
    
    func updateShadowsAndBorderIfNeeded() {
        if let presentedView = presentedView {
            // create shadow path
            presentedView.layer.shadowColor = Constant.shadowColor.cgColor
            presentedView.layer.shadowOffset = Constant.shadowOffset
            presentedView.layer.shadowOpacity = Constant.shadowOpacity
            presentedView.layer.shadowRadius = Constant.shadowRadius
            
            presentedView.subviews.forEach({ (view) in
                view.layer.cornerRadius = Constant.radius
                view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                view.layer.masksToBounds = true
            })
        }
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        updateShadowsAndBorderIfNeeded()
        updateContainerViewFrame()
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        updateContainerViewFrame()
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let top = UIWindow.key?.safeAreaInsets.top ?? 0
        return CGSize(width: parentSize.width, height: parentSize.height - top)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let top = UIWindow.key?.safeAreaInsets.top ?? 0
        let newSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView!.bounds.size)
        
        return CGRect(x: 0, y: top, width: newSize.width, height: newSize.height)
    }
    
    private func updateContainerViewFrame() {
        let frame = frameOfPresentedViewInContainerView
        
        presentedView?.frame = frame
        presentedView?.layoutSubviews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            presentedView?.layer.shadowColor = Constant.shadowColor.cgColor
        }
    }
}
