//
//  UITableView+Rx.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension UITableView {

    /// Reactive wrapper for `UITableView.insertRows(at:with:)`
    var insertRowsEvent: ControlEvent<[IndexPath]> {
        let source = rx.methodInvoked(#selector(UITableView.insertRows(at:with:)))
                .map { a in
                    return a[0] as! [IndexPath]
                }
        return ControlEvent(events: source)
    }

    var reloadDataEvent: ControlEvent<Void> {
        let source = rx.methodInvoked(#selector(UITableView.reloadData))
            .mapToVoid()
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UITableView.endUpdates()`
    var endUpdatesEvent: ControlEvent<Void> {
        let source = rx.methodInvoked(#selector(UITableView.endUpdates))
            .mapToVoid()
                
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for when the `UITableView` inserted rows and ended its updates.
    var insertedItems: ControlEvent<[IndexPath]> {
        let insertEnded = Observable.combineLatest(
                insertRowsEvent.asObservable(),
                endUpdatesEvent.asObservable(),
                resultSelector: { (insertedRows: $0, endUpdates: $1) }
        )
        let source = insertEnded.map { $0.insertedRows }
        return ControlEvent(events: source)
    }
    
    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
    }
}
