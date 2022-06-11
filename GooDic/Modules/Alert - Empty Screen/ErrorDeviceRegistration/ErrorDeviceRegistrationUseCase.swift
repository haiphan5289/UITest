//
//  ErrorDeviceRegistrationUseCase.swift
//  GooDic
//
//  Created by ttvu on 1/14/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

protocol ErrorDeviceRegistrationUseCaseProtocol: CheckAPIFeature {
    
}

struct ErrorDeviceRegistrationUseCase: ErrorDeviceRegistrationUseCaseProtocol {
    @GooInject var cloudService: CloudService
}
