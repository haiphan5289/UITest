//
//  BottomPresentationAnimator.swift
//  GooDic
//
//  Created by ttvu on 5/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class BottomPresentationAnimator: NSObject {
    let isPresentation: Bool
    let animationDuration: TimeInterval
    
    init(isPresentation: Bool, animationDuration: TimeInterval = 0.3) {
        self.isPresentation = isPresentation
        self.animationDuration = animationDuration
        super.init()
    }
}

extension BottomPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresentation ? .to: .from
        let controller = transitionContext.viewController(forKey: key)!
        
        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }
        
        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        dismissedFrame.origin.y = transitionContext.containerView.frame.size.height
        
        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame: dismissedFrame
        
        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        
        if isPresentation {
            let userInfo = Notification.Name.encodeBottomPresentation(controller: controller, height: finalFrame.height, animationDuration: animationDuration)
            NotificationCenter.default.post(name: .willPresentBottomPresentation, object: nil, userInfo: userInfo)
        } else {
            let userInfo = Notification.Name.encodeBottomPresentation(controller: controller, height: 0, animationDuration: animationDuration)
            NotificationCenter.default.post(name: .willDismissBottomPresentation, object: nil, userInfo: userInfo)
        }
        
        UIView.animate(withDuration: animationDuration, animations: {
            controller.view.frame = finalFrame
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }
}
