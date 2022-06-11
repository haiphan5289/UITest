//
//  RxGDProgressViewDelegateProxy.swift
//  GooDic
//
//  Created by ttvu on 8/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension GDProgressView: HasDelegate {
    public typealias Delegate = GDProgressViewDelegate
}

class RxGDProgressViewDelegateProxy
: DelegateProxy<GDProgressView, GDProgressViewDelegate>
, DelegateProxyType
, GDProgressViewDelegate {
    
    public weak private(set) var progressView: GDProgressView?
    
    init(progressView: ParentObject){
        super.init(parentObject: progressView, delegateProxy: RxGDProgressViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register { RxGDProgressViewDelegateProxy(progressView: $0) }
    }
    
    public static func currentDelegate(for object: GDProgressView) -> GDProgressViewDelegate? {
        object.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: GDProgressViewDelegate?, to object: GDProgressView) {
        object.delegate = delegate
    }
    
    
}

