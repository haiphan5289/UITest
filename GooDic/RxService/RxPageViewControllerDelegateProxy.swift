//
//  RxPageViewControllerDelegateProxy.swift
//  GooDic
//
//  Created by ttvu on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

import UIKit
import RxSwift
import RxCocoa

extension UIPageViewController: HasDelegate {
    public typealias Delegate = UIPageViewControllerDelegate
}

class RxPageViewControllerDelegateProxy
: DelegateProxy<UIPageViewController, UIPageViewControllerDelegate>
, DelegateProxyType
, UIPageViewControllerDelegate {
    
    public weak private(set) var pageViewController: UIPageViewController?
    
    init(viewController: ParentObject ){
        self.pageViewController = viewController
        super.init(parentObject: viewController, delegateProxy: RxPageViewControllerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register { RxPageViewControllerDelegateProxy(viewController: $0) }
    }
    
    public static func currentDelegate(for object: UIPageViewController) -> UIPageViewControllerDelegate? {
        object.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: UIPageViewControllerDelegate?, to object: UIPageViewController) {
        object.delegate = delegate
    }
    
//    /// Reactive wrapper for delegate method `pageViewController(_:didFinishAnimating:previousViewControllers, transitionCompleted:)`
//    var didTransition: ControlEvent<(finished: Bool, previousViewControllers: [UIViewController], completed: Bool)> {
//        let source = delegate.methodInvoked(#selector(UIPageViewControllerDelegate.pageViewController(_:didFinishAnimating:previousViewControllers:transitionCompleted:))).map({ value -> (finished: Bool, previousViewControllers: [UIViewController], completed: Bool) in
//            let finished = try castOrThrow(Bool.self, value[1])
//            let previousViewControllers = try castOrThrow([UIViewController].self, value[2])
//            let completed = try castOrThrow(Bool.self, value[3])
//            
//            return (finished: finished, previousViewControllers: previousViewControllers, completed: completed)
//        })
//        
//        return ControlEvent(events: source)
//    }
    
//    /**
//     Reactive wrapper for `delegate` message `tableView:didDeselectRowAtIndexPath:`.
//     */
//    public var itemDeselected: ControlEvent<IndexPath> {
//        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didDeselectRowAt:)))
//            .map { a in
//                return try castOrThrow(IndexPath.self, a[1])
//            }
//
//        return ControlEvent(events: source)
//    }
}
