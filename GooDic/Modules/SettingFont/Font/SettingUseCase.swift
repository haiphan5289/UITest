//
//  SettingUseCase.swift
//  GooDic
//
//  Created by paxcreation on 5/19/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

protocol SettingUseCaseProtocol {
    func getSettingFont() -> SettingFont?
}

struct SettingUseCase: SettingUseCaseProtocol, AuthenticationUseCaseProtocol {
    
    func getSettingFont() -> SettingFont? {
        return AppSettings.settingFont
    }
    
}
