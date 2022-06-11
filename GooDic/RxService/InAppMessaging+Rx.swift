//
//  InAppMessaging+Rx.swift
//  GooDic
//
//  Created by ttvu on 6/10/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit
import FirebaseInAppMessaging

extension Reactive where Base: InAppMessaging {
    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<InAppMessaging, InAppMessagingDisplayDelegate> {
        return RxInAppMessagingDisplayDelegateProxy.proxy(for: base)
    }
    
    /// Reactive wrapper for delegate method `messageClicked(_:with:)`
    var messageClicked: ControlEvent<InAppMessagingAction> {
        let source = delegate.methodInvoked(#selector(InAppMessagingDisplayDelegate.messageClicked(_:with:))).map({ value -> InAppMessagingAction in
            return try castOrThrow(InAppMessagingAction.self, value[1])
        })
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for delegate method `messageDismissed(_:dismissType:)`
    var messageDismissed: ControlEvent<FIRInAppMessagingDismissType> {
        let source = delegate.methodInvoked(#selector(InAppMessagingDisplayDelegate.messageDismissed(_:dismissType:))).map({ value -> FIRInAppMessagingDismissType in
            return try castOrThrow(FIRInAppMessagingDismissType.self, value[1])
        })
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for delegate method `impressionDetected(for:)`
    var impressionDetected: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(InAppMessagingDisplayDelegate.impressionDetected(for:))).mapToVoid()
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for delegate method `displayError(for:error:)`
    var displayError: ControlEvent<Error> {
        let source = delegate.methodInvoked(#selector(InAppMessagingDisplayDelegate.displayError(for:error:))).map({ value -> Error in
            return try castOrThrow(Error.self, value[1])
        })
        
        return ControlEvent(events: source)
    }
}

func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }

    return returnValue
}
