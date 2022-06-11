//
//  SettingSearchVM.swift
//  GooDic
//
//  Created by paxcreation on 5/20/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct SettingSearchVM {
    var navigator: SettingSearchNavigateProtocol
    var useCase: SettingSearchUseCaseProtocol
}

extension SettingSearchVM: ViewModelProtocol {
    struct Input {
        let tapTrigger: Driver<Void>
        let updateSettingSearch: Driver<SettingSearch>
        let dismissTrigger: Driver<Void>
        let movePremium: Driver<Void>
    }
    
    struct Output {
        let tapTrigger: Driver<Void>
        let settingSearch: Driver<SettingSearch>
        let dismissTrigger: Driver<Void>
        let movePremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let tapTrigger = input.tapTrigger
        
        let eventUpdateSearch = AppManager.shared.eventUpdateSearch
            .map{ _ in AppSettings.settingSearch }
            .asDriverOnErrorJustComplete()
        
        let eventUpdateSearchSetting = AppManager.shared.eventUpdateSearchSetting
            .map{ _ in AppSettings.settingSearch }
            .do { s in
                if let settingSearch = s {
                    self.navigator.callBackSetting(settingSearch: settingSearch)
                }
                self.navigator.updateHeightViewAfterPaid()
            }
            .asDriverOnErrorJustComplete()
        
        let getSettingSearch = Driver.merge(eventUpdateSearch, eventUpdateSearchSetting, Driver.just(self.useCase.getSettingSearch()))
            .map { setting -> SettingSearch in
                return setting ?? SettingSearch(isSearch: true, isReplace: false, billingStatus: .free)
            }
        
        let updateSettingSearch = input.updateSettingSearch
            .do { s in
                AppSettings.settingSearch = s
                self.navigator.callBackSetting(settingSearch: s)
            }
        
        let settingSearch = Driver.merge(getSettingSearch, updateSettingSearch)
        
        let dismissTrigger = input.dismissTrigger
            .do { _ in
                self.navigator.dismissSettingSearchView()
            }
        
        let movePremium = input.movePremium
            .do { _ in
                self.navigator.actionPremium()
            }
       
        return Output(
            tapTrigger: tapTrigger,
            settingSearch: settingSearch,
            dismissTrigger: dismissTrigger,
            movePremium: movePremium
        )
    }
}
