//
//  RxInAppMessagingDisplayDelegateProxy.swift
//  GooDic
//
//  Created by ttvu on 6/10/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseInAppMessaging

extension InAppMessaging: HasDelegate {
    public typealias Delegate = InAppMessagingDisplayDelegate
}

class RxInAppMessagingDisplayDelegateProxy
: DelegateProxy<InAppMessaging, InAppMessagingDisplayDelegate>
, DelegateProxyType
, InAppMessagingDisplayDelegate {
    
    public weak private(set) var inAppMessaging: InAppMessaging?
    
    init(inAppMessage: ParentObject ){
        super.init(parentObject: inAppMessage, delegateProxy: RxInAppMessagingDisplayDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register { RxInAppMessagingDisplayDelegateProxy(inAppMessage: $0) }
    }
    
    public static func currentDelegate(for object: InAppMessaging) -> InAppMessagingDisplayDelegate? {
        object.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: InAppMessagingDisplayDelegate?, to object: InAppMessaging) {
        object.delegate = delegate
    }
}
