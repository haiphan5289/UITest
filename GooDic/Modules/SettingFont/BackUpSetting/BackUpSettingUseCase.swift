//
//  DrawPresentUseCase.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol BackUpSettingUseCaseProtocol: AuthenticationUseCaseProtocol {
    func getUserInfo() -> Observable<BillingInfo>
    func getSettingFont() -> Observable<SettingFont>
    func backUpCheck(drafts: [Document]) -> Observable<Bool>
}

struct BackUpSettingUseCase: BackUpSettingUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
    func backUpCheck(drafts: [Document]) -> Observable<Bool> {
        return cloudService.gateway
            .backupCheck(drafts: drafts)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func getUserInfo() -> Observable<BillingInfo> {
        return AppManager.shared.billingInfo.asObservable()
    }
    
    func getSettingFont() -> Observable<SettingFont> {
        return Observable.just(AppSettings.settingFont ?? SettingFont.defaultValue)
    }
}
