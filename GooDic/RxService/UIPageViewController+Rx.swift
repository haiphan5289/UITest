//
//  UIPageViewController+Rx.swift
//  GooDic
//
//  Created by ttvu on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIPageViewController {
    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<UIPageViewController, UIPageViewControllerDelegate> {
        return RxPageViewControllerDelegateProxy.proxy(for: base)
    }
    
    /// Reactive wrapper for delegate method `pageViewController(_:willTransitionTo:)`
    var willTransitionTo: ControlEvent<[UIViewController]> {
        let source = delegate.methodInvoked(#selector(UIPageViewControllerDelegate.pageViewController(_:willTransitionTo:))).map({ value -> [UIViewController] in
            let viewControllers = try castOrThrow([UIViewController].self, value[1])
            return viewControllers
        })
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for delegate method `pageViewController(_:didFinishAnimating:previousViewControllers, transitionCompleted:)`
    var didTransition: ControlEvent<(finished: Bool, previousViewControllers: [UIViewController], completed: Bool)> {
        let source = delegate.methodInvoked(#selector(UIPageViewControllerDelegate.pageViewController(_:didFinishAnimating:previousViewControllers:transitionCompleted:))).map({ value -> (finished: Bool, previousViewControllers: [UIViewController], completed: Bool) in
            let finished = try castOrThrow(Bool.self, value[1])
            let previousViewControllers = try castOrThrow([UIViewController].self, value[2])
            let completed = try castOrThrow(Bool.self, value[3])
            
            return (finished: finished, previousViewControllers: previousViewControllers, completed: completed)
        })
        
        return ControlEvent(events: source)
    }
}
