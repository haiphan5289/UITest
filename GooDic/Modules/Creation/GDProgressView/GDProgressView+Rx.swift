//
//  GDProgressView+Rx.swift
//  GooDic
//
//  Created by ttvu on 6/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: GDProgressView {
    
    /// Reactive wrapper for `delegate`.
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    internal var delegate: DelegateProxy<GDProgressView, GDProgressViewDelegate> {
        RxGDProgressViewDelegateProxy.proxy(for: base)
    }
    
    /// Bindable sink for `state` property.
    var state: Binder<ProgressState> {
        return Binder(self.base) { owner, state in
            owner.state = state
        }
    }
    
    /// Reactive wrapper for `delegate` message `progressView(_:didChange:)`.
    var didChangeState: ControlEvent<Void> {
        let source = delegate
            .methodInvoked(#selector(GDProgressViewDelegate.progressView(_:didChange:)))
            .mapToVoid()

        return ControlEvent(events: source)
    }
}
