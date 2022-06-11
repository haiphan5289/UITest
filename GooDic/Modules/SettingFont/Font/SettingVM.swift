//
//  SettingVM.swift
//  GooDic
//
//  Created by paxcreation on 5/19/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct SettingViewModel {
    var navigator: SettingNavigateProtocol
    var useCase: SettingUseCaseProtocol
    var onCloud: Bool
}

extension SettingViewModel: ViewModelProtocol {
    struct Input {
        let updateSettingFont: Driver<SettingFont>
        let dismissTrigger: Driver<Void>
        let actionShareTrigger: Driver<Void>
        let eventShowAlertAutoSave: Driver<Void>
    }
    
    struct Output {
        let updateSettingFont: Driver<SettingFont>
        let settingFont: Driver<SettingFont>
        let dismissTrigger: Driver<Void>
        let actionShareTrigger: Driver<Void>
        let detectOnCloud: Driver<Bool>
        let eventShowAlertAutoSave: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let updateSettingFont = input.updateSettingFont
            .do { s in
                self.navigator.callBackSetting(settingFont: s)
            }
        
        let settingFont = Driver.just(self.useCase.getSettingFont())
            .map { setting -> SettingFont in
                return setting ?? SettingFont.defaultValue
            }
        
        let dismissTrigger = input.dismissTrigger
            .do { _ in
                if onCloud {
                    self.navigator.popVC()
                } else {
                    self.navigator.dismissDelegate()
                }
                
            }
        
        let actionShareTrigger = input.actionShareTrigger
            .do{ _ in
                self.navigator.actionShare()
            }
        
        let detectOnCloud = Driver.just(self.onCloud)
        
        let eventShowAlertAutoSave = input.eventShowAlertAutoSave
            .asObservable()
            .flatMap({ _ -> Driver<Void> in
                return self.navigator.showMessage(L10n.SettingFont.alertAutoSave).asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
       
        return Output(
            updateSettingFont: updateSettingFont,
            settingFont: settingFont,
            dismissTrigger: dismissTrigger,
            actionShareTrigger: actionShareTrigger,
            detectOnCloud: detectOnCloud,
            eventShowAlertAutoSave: eventShowAlertAutoSave
        )
    }
}
