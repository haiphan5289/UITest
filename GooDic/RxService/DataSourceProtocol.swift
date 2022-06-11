//
//  DataSourceProtocol.swift
//  GooDic
//
//  Created by ttvu on 5/27/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol DataSourceProtocol {
}

extension DataSourceProtocol {
    func checkIfDataIsEmpty<T: Collection>(trigger: Driver<Bool>, items: Driver<T>) -> Driver<Bool> {
        return Driver
            .combineLatest(trigger, items) {
                ($0, $1.isEmpty)
            }
            .map { loading, isEmpty -> Bool in
                if loading { return false }
                return isEmpty
            }
            .distinctUntilChanged()
    }
    
    func select<T>(trigger: Driver<IndexPath>, items: Driver<[T]>) -> Driver<T> {
        return trigger
            .withLatestFrom(items) {
                return ($0, $1)
            }
            .filter { indexPath, items in indexPath.row < items.count }
            .map { indexPath, items in
                return items[indexPath.row]
            }
    }
}
