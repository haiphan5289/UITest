//
//  RxViewModelProtocol.swift
//  GooDic
//
//  Created by ttvu on 10/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension ViewModelProtocol {
    public func checkIfDataIsEmpty<T: Collection>(trigger: Driver<Bool>, items: Driver<T>) -> Driver<Bool> {
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
}
