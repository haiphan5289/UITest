//
//  Suggestion+Notification.swift
//  GooDic
//
//  Created by ttvu on 11/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import CoreGraphics

extension Notification.Name {
    static let willPresentSuggestion = Notification.Name("willPresentSuggestion")
    static let willDismissSuggestion = Notification.Name("willDismissSuggestion")
    
    static func encodeSuggestion(height: CGFloat, animationDuration: TimeInterval) -> [AnyHashable: Any] {
        return ["height": height, "animationDuration": animationDuration]
    }
    
    static func decodeSuggestion(notification: Notification) -> (height: CGFloat, duration: TimeInterval) {
        let height: CGFloat = notification.userInfo?["height"] as? CGFloat ?? 0
        let duration: TimeInterval = notification.userInfo?["animationDuration"] as? TimeInterval ?? 0
        return (height: height, duration: duration)
    }
}
