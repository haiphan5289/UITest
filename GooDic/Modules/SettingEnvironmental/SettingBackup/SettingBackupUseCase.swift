//
//  SettingBackupUseCase.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol SettingBackupUseCaseProtocol: AuthenticationUseCaseProtocol {
    func getBillingInfo() -> Observable<BillingInfo>
    func postBackupSettings(settingBackupModel: SettingBackupModel, settingKey: String) -> Observable<Void>
    func getBackupSettings(settingKey: String) -> Observable<SettingBackupModel?>
}

struct SettingBackupUseCase: SettingBackupUseCaseProtocol {

    
    
    @GooInject var cloudService: CloudService
    
    func getBillingInfo() -> Observable<BillingInfo> {
        return AppManager.shared.billingInfo.asObservable()
    }
    
    func postBackupSettings(settingBackupModel: SettingBackupModel, settingKey: String) -> Observable<Void> {
        return cloudService.gateway
            .postBackupSettings(settingBackupModel: settingBackupModel, settingKey: settingKey)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    func getBackupSettings(settingKey: String) -> Observable<SettingBackupModel?> {
        return cloudService.gateway
            .getBackupSettings(settingKey: settingKey)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
}
