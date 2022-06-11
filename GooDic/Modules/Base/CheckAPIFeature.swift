//
//  CheckAPIFeature.swift
//  GooDic
//
//  Created by ttvu on 1/14/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol CheckAPIFeature {
    var cloudService: CloudService { get }
    func checkAPIStatus() -> Observable<Void>
}

extension CheckAPIFeature {
    func checkAPIStatus() -> Observable<Void> {
        cloudService.gateway
            .getAPIStatus()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
}
