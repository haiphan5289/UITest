//
//  BottomPresentationDelegate.swift
//  GooDic
//
//  Created by ttvu on 5/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BottomPresentationDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var heightType: BottomPresentationHeightType
    var animationDuration: TimeInterval
    var isPassingTouchEvent = true
    var presentationController: BottomPresentationController?
    
    init(heightType: BottomPresentationHeightType, animationDuration: TimeInterval,
         isPassingTouchEvent: Bool = true) {
        self.heightType = heightType
        self.animationDuration = animationDuration
        self.isPassingTouchEvent = isPassingTouchEvent
    }
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        presentationController = BottomPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController?.isPassingTouchEvent = isPassingTouchEvent
        presentationController?.type = heightType
        
        return presentationController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomPresentationAnimator(isPresentation: true, animationDuration: animationDuration)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomPresentationAnimator(isPresentation: false, animationDuration: animationDuration)
    }
}
