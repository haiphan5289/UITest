//
//  TutorialViewModel.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct TutorialViewModel {
    let navigator: TutorialNavigateProtocol
    let useCase: TutorialUseCase
    
    init(useCase: TutorialUseCase, navigator: TutorialNavigateProtocol) {
        self.useCase = useCase
        self.navigator = navigator
    }
}

extension TutorialViewModel: ViewModelProtocol {
    struct Input {
        let loadData: Driver<Void>
        let nextTrigger: Driver<Void>
    }
    
    struct Output {
        let loaded: Driver<Void>
        let toMainFlow: Driver<Void>
        let toPurchaseFlow: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let loaded = input.loadData
            .do(onNext: {
                self.useCase.learnedTrash()
                self.useCase.updateFirstInstallBuildVersion()
            })
        
        let isShowPremium = AppManager.shared.eventShouldAddStorePayment.asObservable()
        let toMainFlow =  input.nextTrigger.withLatestFrom(isShowPremium.asDriverOnErrorJustComplete(), resultSelector: { (data: $0, isShowPremium: $1) })
            .do(onNext: { (_ ,isShowPremium) in
                self.useCase.learnedTutorial()
                if (isShowPremium) {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                } else {
                    self.navigator.toLogin()
                }
            }).mapToVoid()
                    
        let toPurchaseFlow = self.navigator.isDismissRegisterPremium.asObservable()
                .filter({$0})
                .do { _ in
                    if (AppManager.shared.userInfo.value == nil) {
                        self.navigator.toLogin()
                    } else {
                        self.navigator.toHome()
                    }
                }.asDriverOnErrorJustComplete().mapToVoid()

        return Output(
            loaded: loaded,
            toMainFlow: toMainFlow,
            toPurchaseFlow: toPurchaseFlow
        )
    }
}
