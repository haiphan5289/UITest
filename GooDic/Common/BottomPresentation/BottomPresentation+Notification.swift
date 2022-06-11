//
//  BottomPresentation+Notification.swift
//  GooDic
//
//  Created by ttvu on 5/27/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension Notification.Name {
    static let willPresentBottomPresentation = Notification.Name("willPresentBottomPresentation")
    static let willDismissBottomPresentation = Notification.Name("willDismissBottomPresentation")
    
    static func encodeBottomPresentation(controller: UIViewController?, height: CGFloat, animationDuration: TimeInterval) -> [AnyHashable: Any] {
        if controller == nil {
            return ["height": height, "animationDuration": animationDuration]
        }
        else {
            return ["controller": controller!, "height": height, "animationDuration": animationDuration]
        }
    }
    
    static func decodeBottomPresentation(notification: Notification) -> (controller: UIViewController?, height: CGFloat, duration: TimeInterval) {
        let controller: UIViewController? = notification.userInfo?["controller"] as? UIViewController
        let height: CGFloat = notification.userInfo?["height"] as? CGFloat ?? 0
        let duration: TimeInterval = notification.userInfo?["animationDuration"] as? TimeInterval ?? 0
        return (controller: controller, height: height, duration: duration)
    }
}

extension Notification.Name {
    static let hideTabBar = Notification.Name("hideTabBar")
    static let showTabBar = Notification.Name("showTabBar")
}
