//
//  ObservableType+Retry.swift
//  GooDic
//
//  Created by ttvu on 1/13/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import RxSwift

extension ObservableType {
    
    func retry(_ maxAttemptCount: Int, shouldRetry: @escaping (Error) -> Bool) -> Observable<Element> {
        return retryWhen { (errors) in
            return errors.scan(0) { (attempts, error) in
                guard attempts < maxAttemptCount, shouldRetry(error) else {
                    throw error
                }
                
                return attempts + 1
            }
        }
    }
}
