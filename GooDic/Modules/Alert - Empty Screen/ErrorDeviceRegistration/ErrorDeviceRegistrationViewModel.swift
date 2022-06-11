//
//  ErrorDeviceRegistrationViewModel.swift
//  GooDic
//
//  Created by ttvu on 1/14/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct ErrorDeviceRegistrationViewModel {
    let useCase: ErrorDeviceRegistrationUseCaseProtocol
    let navigator: ErrorDeviceRegistrationNavigateProtocol
    let typeRegister: RouteLogin
}

extension ErrorDeviceRegistrationViewModel: ViewModelProtocol {
    struct Input {
        let deviceTrigger: Driver<Void>
        let viewWillDisappear: Driver<Void>
    }
    
    struct Output {
        let openDeviceScreen: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let cancelTrigger = input.viewWillDisappear
        let openDeviceScreen = openDeviceScreenFlow(trigger: input.deviceTrigger,
                                                    cancelTrigger: cancelTrigger)
        return Output(
            openDeviceScreen: openDeviceScreen
        )
    }
    
    func openDeviceScreenFlow(trigger: Driver<Void>,
                              cancelTrigger: Driver<Void>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let error = ErrorTracker()
        let errorHandler = error
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.ErrorDevice.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                          
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        let open = trigger
            .withLatestFrom(activityIndicator)
            .filter({ $0 == false })
            .flatMap({ _ in
                return self.useCase.checkAPIStatus()
                    .trackActivity(activityIndicator)
                    .trackError(error)
                    .takeUntil(cancelTrigger.asObservable())
                    .asDriverOnErrorJustComplete()
            })
            .do(onNext: {
                self.navigator.toDevicesScreen(typeRegister: self.typeRegister)
            })
        
        return Driver.merge(open, errorHandler)
    }
}
