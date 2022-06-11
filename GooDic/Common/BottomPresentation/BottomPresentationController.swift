//
//  BottomPresentationController.swift
//  GooDic
//
//  Created by ttvu on 5/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

enum BottomPresentationHeightType: Equatable {
    case equal(CGFloat)
    case safeArea
    case lowerUnit(CGFloat)
    case percent(CGFloat) // 0...1
    case fullView
}

class BottomPresentationController: UIPresentationController {
    
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
    }
    
    var isPassingTouchEvent = false
    var type: BottomPresentationHeightType = .percent(0.5)
    var currentSize: CGSize = .zero
    
    func updateShadowsAndBorderIfNeeded() {
        if let presentedView = presentedView {
            let radius: CGFloat = Constant.radius
            
            // create shadow path
            let cornerRadius: CGSize = CGSize(width: radius, height: radius)
            let path = UIBezierPath(roundRect: presentedView.frame, topLeftRadius: cornerRadius, topRightRadius: cornerRadius)
            let shadowLayer = CAShapeLayer()
            shadowLayer.path = path.cgPath
            shadowLayer.fillColor = UIColor.clear.cgColor
            
            presentedView.layer.shadowPath = path.cgPath
            presentedView.layer.shadowColor = Constant.shadowColor.cgColor
            presentedView.layer.shadowOffset = Constant.shadowOffset
            presentedView.layer.shadowOpacity = Constant.shadowOpacity
            presentedView.layer.shadowRadius = Constant.shadowRadius
            presentedView.layer.masksToBounds = false
            presentedView.layer.shouldRasterize = true
            presentedView.layer.rasterizationScale = UIScreen.main.scale
            
            presentedView.layer.insertSublayer(shadowLayer, at: 0)
            presentedView.isUserInteractionEnabled = true
            
            presentedView.subviews.forEach({ (view) in
                view.layer.cornerRadius = radius
                view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                view.layer.masksToBounds = true
            })
        }
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        updateShadowsAndBorderIfNeeded()
        if type == .safeArea {
            currentSize = UIScreen.main.bounds.size
        } else {
            currentSize = preferredContentSize
        }
        
        if isPassingTouchEvent {
            updateContainerViewFrame()
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let _ = presentingViewController.transitionCoordinator {
            
        } else {
            presentedView?.frame = frameOfPresentedViewInContainerView
        }
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width , height: getEstimatedHeightOfContainerView())
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let newSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: currentSize)
        
        return CGRect(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height - newSize.height), size: newSize)
    }
    
    private func getEstimatedHeightOfContainerView() -> CGFloat {
        switch type {
        case let .percent(value):
            return value < 0.0 ? 0.0 : (value > 1.0 ? currentSize.height : currentSize.height * value)
        case let .lowerUnit(value):
            return currentSize.height - value
        case let .equal(value):
            return value
        case .safeArea:
            if let windowSize = UIWindow.key?.bounds.size, currentSize == windowSize {
                // full screen
                return currentSize.height - (UIWindow.key?.safeAreaInsets.top ?? 00)
            }
            
            return currentSize.height
        case .fullView:
            return currentSize.height
        }
    }

    private func updateContainerViewFrame() {
        let height = getEstimatedHeightOfContainerView()
        var frame = frameOfPresentedViewInContainerView
        
        if type != .fullView {
            frame.origin.y = UIScreen.main.bounds.height - height
        }
        
        containerView?.frame = frame
        print("abc \(frame)")
        containerView?.layoutIfNeeded()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("abc a \(size)")
        
        if let parentTransition = self.presentingViewController.transitioningDelegate as? BottomPresentationDelegate,
           let parentSize = parentTransition.presentationController?.currentSize,
           let parentHeight = parentTransition.presentationController?.getEstimatedHeightOfContainerView() {
            if parentSize != size, type == .safeArea {
                let minValue = min(parentSize.width, parentSize.height)
                let maxValue = max(parentSize.width, parentSize.height)

                if parentTransition.heightType == .safeArea {
                    let topSafeArea = (UIWindow.key?.safeAreaInsets.top ?? 00)
                    let minSize = min(size.width, size.height)
                    
                    if abs(minSize - minValue) <= topSafeArea {
                        currentSize = CGSize(width: minValue, height: maxValue)
                    } else {
                        currentSize = CGSize(width: maxValue, height: minValue)
                    }
                } else {
                    if size.height == parentHeight && size.width == maxValue {
                        currentSize = CGSize(width: maxValue, height: minValue)
                    } else {
                        currentSize = CGSize(width: minValue, height: maxValue)
                    }
                }
            }
        } else {
            currentSize = size
        }
        
        coordinator.animate(alongsideTransition: { context in
            self.updateContainerViewFrame()
            self.updateShadowsAndBorderIfNeeded()
        })
    }
}
