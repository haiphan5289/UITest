//
//  SettingSearchUseCase.swift
//  GooDic
//
//  Created by paxcreation on 5/20/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

protocol SettingSearchUseCaseProtocol {
    func getSettingSearch() -> SettingSearch?
}

struct SettingSearchUseCase: SettingSearchUseCaseProtocol, AuthenticationUseCaseProtocol {
    
    func getSettingSearch() -> SettingSearch? {
        return AppSettings.settingSearch
    }
    
}
