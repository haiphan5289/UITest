//
//  UIView+Separator.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

// ref: https://github.com/bugnitude/UIView-Separator/blob/master/UIView%2BSeparator.swift

extension UIView {
    
    enum SeparatorPosition {
        case top
        case bottom
        case left
        case right
    }

    @discardableResult
    func addSeparator(at position: SeparatorPosition, color: UIColor, weight: CGFloat = 1.0 / UIScreen.main.scale, insets: UIEdgeInsets = .zero) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        self.bringSubviewToFront(view)
        self.addSubview(view)
        
        let safeArea = self.safeAreaLayoutGuide
        switch position {
        case .top:
            view.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: insets.top).isActive = true
            view.leftAnchor.constraint(equalTo: safeArea.leftAnchor, constant: insets.left).isActive = true
            view.rightAnchor.constraint(equalTo: safeArea.rightAnchor, constant: -insets.right).isActive = true
            view.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .bottom:
            view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -insets.bottom).isActive = true
            view.leftAnchor.constraint(equalTo: safeArea.leftAnchor, constant: insets.left).isActive = true
            view.rightAnchor.constraint(equalTo: safeArea.rightAnchor, constant: -insets.right).isActive = true
            view.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .left:
            view.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: insets.top).isActive = true
            view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -insets.bottom).isActive = true
            view.leftAnchor.constraint(equalTo: safeArea.leftAnchor, constant: insets.left).isActive = true
            view.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .right:
            view.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: insets.top).isActive = true
            view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -insets.bottom).isActive = true
            view.rightAnchor.constraint(equalTo: safeArea.rightAnchor, constant: -insets.right).isActive = true
            view.widthAnchor.constraint(equalToConstant: weight).isActive = true
        }
        
        return view
    }
    
}
extension UIView {
    
    var safeAreaBottom: CGFloat {
            if #available(iOS 11, *) {
               if let window = UIApplication.shared.keyWindow {
                   return window.safeAreaInsets.bottom
               }
            }
            return 0
       }
}
