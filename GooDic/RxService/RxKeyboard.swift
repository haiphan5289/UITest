//
//  RxKeyboard.swift
//  GooDic
//
//  Created by ttvu on 9/8/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct PresentAnim {
    let height: CGFloat
    let duration: TimeInterval
    
    static let empty: PresentAnim = PresentAnim(height: 0, duration: 0)
}

func keyboardHandle() -> Observable<PresentAnim> {
    let willShowTrigger = NotificationCenter.default.rx
        .notification(UIResponder.keyboardWillShowNotification)
        .map({ data -> PresentAnim in
            let duration: TimeInterval = (data.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
            let height = (data.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0.0
            return PresentAnim(height: height, duration: duration)
        })
    
    let willDismissTrigger = NotificationCenter.default.rx
        .notification(UIResponder.keyboardWillHideNotification)
        .map({ data -> PresentAnim in
            let duration: TimeInterval = (data.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
            return PresentAnim(height: 0.0, duration: duration)
        })
    
    return Observable.from([willShowTrigger, willDismissTrigger])
        .merge()
}
