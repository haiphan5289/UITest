//
//  UIView+TutorialPopup.swift
//  GooDic
//
//  Created by ttvu on 6/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

func -=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func +=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

extension UIView {
    
    public enum AnchorPoint {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case centerLeft
        case centerRight
        case centerTop
        case centerBottom
        case center
        case anchor(CGPoint)
        
        func position(form rect: CGRect) -> CGPoint {
            switch self {
            case .topLeft: return rect.topLeft
            case .topRight: return rect.topRight
            case .bottomLeft: return rect.bottomLeft
            case .bottomRight: return rect.bottomRight
            case .centerRight: return rect.centerRight
            case .centerLeft: return rect.centerLeft
            case .centerTop: return rect.centerTop
            case .centerBottom: return rect.centerBottom
            case .center: return rect.center
            case let .anchor(delta):
                return CGPoint(x: delta.x, y: delta.y)
            }
        }
        
        func rect(from point: CGPoint, size: CGSize) -> CGRect {
            var origin: CGPoint = point
            switch self {
            case .topLeft:
                break
            case .topRight:
                origin -= CGPoint(x: size.width, y: 0)
            case .bottomLeft:
                origin -= CGPoint(x: 0, y: size.height)
            case .bottomRight:
                origin -= CGPoint(x: size.width, y: size.height)
            case .centerLeft:
                origin -= CGPoint(x: 0, y: size.height * 0.5)
            case .centerRight:
                origin -= CGPoint(x: size.width, y: size.height * 0.5)
            case .centerTop:
                origin -= CGPoint(x: size.width * 0.5, y: 0)
            case .centerBottom:
                origin -= CGPoint(x: size.width * 0.5, y: size.height)
            case .center:
                origin -= CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            case let .anchor(delta):
                origin -= delta
            }
            
            return CGRect(origin: origin, size: size)
        }
    }
    
    public struct AnimConfig {
        var duration: TimeInterval = 0.8
        var delay: TimeInterval = 0.3
        var popupAnchorPoint: AnchorPoint = .center
        var targetAnchorPoint: AnchorPoint = .center
    }
    
    /// show popup with animation
    /// - Parameters:
    ///   - popup: popup
    ///   - targetRect: to calculate position
    ///   - config: to calculate position
    ///   - controlView: popup's center point will be attached to controlView's center point
    func show(popup: UIView, targetRect: CGRect, config: AnimConfig, controlView: UIView? = nil) {
        if let _ = self.subviews.first(where: { $0 == popup }) {
            return
        }
        
        let point = config.targetAnchorPoint.position(form: targetRect)
        let finalFrame = config.popupAnchorPoint.rect(from: point, size: popup.bounds.size)
        
        self.addSubview(popup)
        if let controlView = controlView {
            popup.translatesAutoresizingMaskIntoConstraints = false
            popup.removeConstraints(popup.constraints)
            NSLayoutConstraint.activate([
                popup.widthAnchor.constraint(equalToConstant: popup.bounds.width),
                popup.heightAnchor.constraint(equalToConstant: popup.bounds.height),
                popup.centerXAnchor.constraint(equalTo: controlView.centerXAnchor, constant: finalFrame.center.x - controlView.center.x),
                popup.centerYAnchor.constraint(equalTo: controlView.centerYAnchor, constant: finalFrame.center.y - controlView.center.y)
            ])
        }
        
        var finalPoint = config.popupAnchorPoint.position(form: finalFrame)
        finalPoint.x += finalFrame.origin.x
        finalPoint.y += finalFrame.origin.y
        popup.alpha = 0
        popup.frame = CGRect(origin: point, size: .zero)
        
        UIView.animate(withDuration: config.duration, delay: config.delay, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: [.curveEaseInOut], animations: {
            popup.alpha = 1
            popup.frame = finalFrame
        })
    }
    
    func dismiss(popup: UIView, verticalAnim: CGFloat = 10) {
        var finalFrame = popup.frame
        finalFrame.origin.y += verticalAnim
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            popup.alpha = 0
            popup.frame = finalFrame
        }, completion: { _ in
            popup.removeFromSuperview()
        })
    }
}

